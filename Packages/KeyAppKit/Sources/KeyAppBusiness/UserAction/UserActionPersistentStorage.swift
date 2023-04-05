//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Foundation
import KeyAppKitCore

public protocol UserActionPersistentStorage {
    // var encoder: Encoder { get }
    // var decoder: Decoder { get }

    func insert(in table: String, userAction: some UserAction) async throws

    func delete(in table: String, userAction: some UserAction) async throws

    func query<T: UserAction>(in table: String, type: T.Type) async throws -> [T]
}

public actor UserActionPersistentStorageWithUserDefault: UserActionPersistentStorage {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    struct Database: Codable {
        var tables: [String: Table] = [:]

        mutating func insert(in table: String, record: Record) {
            if !tables.keys.contains(table) {
                tables[table] = Table(name: table)
            }

            tables[table]!.records.insert(record)
        }

        mutating func delete(in table: String, id: String) {
            if !tables.keys.contains(table) {
                tables[table] = Table(name: table)
            }

            tables[table]!.records = tables[table]!.records.filter { $0.id != id }
        }
    }

    struct Table: Hashable, Codable {
        let name: String
        var records: Set<Record> = []

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }

    struct Record: Hashable, Codable {
        let id: String
        var data: Data

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    var database: Database = .init()

    let errorObserver: ErrorObserver

    public init(errorObserver: ErrorObserver) {
        self.errorObserver = errorObserver

        // Restore data
        if let data = UserDefaults.standard.data(forKey: "UserActionPersistentStorageWithUserDefault") {
            if let database = try? decoder.decode(Database.self, from: data) {
                self.database = database
            }
        }
    }

    public func insert(in table: String, userAction: some UserAction) async throws {
        database.insert(in: table, record: .init(id: userAction.id, data: try encoder.encode(userAction)))

        await flush()
    }

    public func delete(in table: String, userAction: some UserAction) async throws {
        database.delete(in: table, id: userAction.id)

        await flush()
    }

    public func query<T>(in table: String, type: T.Type) async throws -> [T] where T: UserAction {
        if let table = database.tables[table] {
            return try table.records.map { record in
                try decoder.decode(type, from: record.data)
            }
        }
        return []
    }

    func flush() async {
        do {
            let encodedDatabase = try encoder.encode(database)
            UserDefaults.standard.setValue(encodedDatabase, forKey: "UserActionPersistentStorageWithUserDefault")
        } catch {
            errorObserver.handleError(error)
        }
    }
}
