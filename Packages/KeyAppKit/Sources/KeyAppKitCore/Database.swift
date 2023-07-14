import Foundation

public protocol Database<Key, Value> {
    associatedtype Key: Codable, Hashable
    associatedtype Value: Codable, Hashable

    func read(for key: Key) async throws -> Value?
    func write(for key: Key, value: Value) async throws

    func clear() async throws
}

/// Simple storable database
///
/// Attention: Do not create multiple instance of this object!
public actor StorableDatabase<Key: Codable & Hashable, Value: Codable & Hashable>: Database {
    public typealias Key = Key
    public typealias Value = Value

    var initialised: Bool = false
    var data: [Key: Value] = [:]

    let filePath: String
    let storage: Storage

    public init(filePath: String, storage: Storage) {
        self.filePath = filePath
        self.storage = storage
    }

    public func read(for key: Key) async throws -> Value? {
        if initialised == false {
            try await loadDataFromFile()
        }

        return data[key]
    }

    public func write(for key: Key, value: Value) async throws {
        data[key] = value
        try await flush()
    }

    func loadDataFromFile() async throws {
        if let encodedData = try await storage.load(for: filePath) {
            data = try JSONDecoder().decode([Key: Value].self, from: encodedData)
        }
    }

    public func flush() async throws {
        let encodedData = try JSONEncoder().encode(data)
        try await storage.save(for: filePath, data: encodedData)
    }

    public func clear() async throws {
        data = [:]
        try await flush()
    }
}

/// Simple storable database with expiration mechanic
///
/// Attention: Do not create multiple instance of this object!
public actor LifetimeDatabase<Key: Codable & Hashable, Value: Codable & Hashable>: Database {
    public typealias Key = Key
    public typealias Value = Value

    struct Record: Codable, Hashable {
        let timestamps: Date
        let lifetime: TimeInterval
        let value: Value
    }

    var initialised: Bool = false
    var data: [Key: Record] = [:]

    let filePath: String
    let storage: Storage
    let autoFlush: Bool
    let defaultLifetime: TimeInterval

    public init(filePath: String, storage: Storage, autoFlush: Bool = true, defaultLifetime: TimeInterval) {
        self.filePath = filePath
        self.storage = storage
        self.autoFlush = autoFlush
        self.defaultLifetime = defaultLifetime
    }

    public func read(for key: Key) async throws -> Value? {
        if initialised == false {
            try await loadDataFromFile()
            initialised = true
        }

        guard let record = data[key] else { return nil }

        if record.timestamps + record.lifetime >= Date() {
            return record.value
        } else {
            data[key] = nil
            return nil
        }
    }

    public func write(for key: Key, value: Value, lifetime: TimeInterval? = nil) async throws {
        data[key] = .init(timestamps: Date(), lifetime: lifetime ?? defaultLifetime, value: value)

        if autoFlush {
            try await flush()
        }
    }

    public func write(for key: Key, value: Value) async throws {
        data[key] = .init(timestamps: Date(), lifetime: defaultLifetime, value: value)

        if autoFlush {
            try await flush()
        }
    }

    func loadDataFromFile() async throws {
        if let encodedData = try await storage.load(for: filePath) {
            data = try JSONDecoder().decode([Key: Record].self, from: encodedData)
        }
    }

    public func flush() async throws {
        let encodedData = try JSONEncoder().encode(data)
        try await storage.save(for: filePath, data: encodedData)
    }

    public func clear() async throws {
        data = [:]
        try await flush()
    }
}
