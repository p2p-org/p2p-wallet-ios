//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.04.2023.
//

import Combine
import Foundation

public actor SynchronizedDatabase<Key: Hashable & Codable, Value: Codable> {
    private var data: [Key: Value] = [:] {
        didSet {
            onUpdate.send(data)
        }
    }

    public nonisolated let onUpdate: PassthroughSubject<[Key: Value], Never> = .init()

    public init() {}

    public func set(for key: Key, _ value: Value) async {
        data[key] = value
    }

    public func get(for key: Key) async -> Value? {
        data[key]
    }

    public func remove(key: Key) async {
        data[key] = nil
    }

    public func contains(_ key: Key) async -> Bool {
        data[key] != nil
    }

    public func values() async -> [Value] {
        Array(data.values)
    }
}

public extension SynchronizedDatabase {
    nonisolated func link(
        to userActionPersistentStorage: UserActionPersistentStorage,
        in table: String
    ) -> AnyCancellable {
        onUpdate
            .sink { [weak userActionPersistentStorage] data in
                guard let data = try? JSONEncoder().encode(data) else { return }
                userActionPersistentStorage?.save(in: table, data: data)
            }
    }

    func restore(
        from userActionPersistentStorage: UserActionPersistentStorage,
        table: String,
        filter: (Key, Value) -> Bool = { _, _ in true }
    ) async throws {
        let data = userActionPersistentStorage.restore(table: table)
        guard let data else { return }
        let restoredData = try JSONDecoder().decode([Key: Value].self, from: data)

        self.data = restoredData.filter(filter)
    }
}
