// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public final class LongTermCache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date
    private let entryLifetime: TimeInterval
    private let keyTracker = KeyTracker()

    public init(
        dateProvider: @escaping () -> Date = Date.init,
        entryLifetime: TimeInterval = 12 * 60 * 60,
        maximumEntryCount: Int = 50
    ) {
        self.dateProvider = dateProvider
        self.entryLifetime = entryLifetime
        wrapped.countLimit = maximumEntryCount
        wrapped.delegate = keyTracker
    }

    public func insert(_ value: Value, forKey key: Key) {
        let date = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(key: key, value: value, expirationDate: date)
        wrapped.setObject(entry, forKey: WrappedKey(key))
        keyTracker.insert(key)
    }

    public func value(forKey key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }

        guard dateProvider() < entry.expirationDate else {
            // Discard values that have expired
            removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    public func removeValue(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }
}

private extension LongTermCache {
    final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        override var hash: Int { key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }
}

public extension LongTermCache {
    final class KeyTracker: NSObject, NSCacheDelegate {
        /// Thread-safe
        private var _lock: UnsafeMutablePointer<os_unfair_lock>

        private var keys = Set<Key>()

        override public init() {
            _lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
            _lock.initialize(to: os_unfair_lock())

            super.init()
        }

        deinit {
            _lock.deallocate()
        }

        public func insert(_ key: Key) {
            os_unfair_lock_lock(_lock)
            keys.insert(key)
            os_unfair_lock_unlock(_lock)
        }

        public func cache(_: NSCache<AnyObject, AnyObject>, willEvictObject object: Any) {
            guard let entry = object as? Entry else {
                return
            }

            os_unfair_lock_lock(_lock)
            keys.remove(entry.key)
            os_unfair_lock_unlock(_lock)
        }

        public func getKeys() -> Set<Key> {
            os_unfair_lock_lock(_lock)
            defer { os_unfair_lock_unlock(_lock) }
            return Set(keys)
        }
    }

    final class Entry {
        let key: Key
        let value: Value
        let expirationDate: Date

        init(key: Key, value: Value, expirationDate: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

extension LongTermCache.Entry: Codable where Key: Codable, Value: Codable {}

extension LongTermCache {
    subscript(key: Key) -> Value? {
        get { value(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                removeValue(forKey: key)
                return
            }

            insert(value, forKey: key)
        }
    }
}

extension LongTermCache: Codable where Key: Codable, Value: Codable {
    public convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyTracker.getKeys().compactMap(entry))
    }
}

public extension LongTermCache where Key: Codable, Value: Codable {
    func saveToDisk(
        withName name: String,
        using fileManager: FileManager = .default
    ) throws {
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let fileURL = folderURLs[0].appendingPathComponent(name + ".cache")
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL)
    }
}

public extension LongTermCache {
    func entry(forKey key: Key) -> Entry? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }

        guard dateProvider() < entry.expirationDate else {
            removeValue(forKey: key)
            return nil
        }

        return entry
    }

    func insert(_ entry: Entry) {
        wrapped.setObject(entry, forKey: WrappedKey(entry.key))
        keyTracker.insert(entry.key)
    }
}
