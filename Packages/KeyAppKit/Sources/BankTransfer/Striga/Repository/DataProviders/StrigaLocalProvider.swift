import Foundation

public protocol StrigaLocalProvider {
    func getCachedRegistrationData() async -> StrigaUserDetailsResponse?
    func save(registrationData: StrigaUserDetailsResponse) async throws

    func getCachedUserData() async -> UserData?
    func save(userData: UserData) async throws

    func clear() async
}

public actor StrigaLocalProviderImpl {

    private let registrationFile: URL = {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/striga-registration.data")
    }()

    private let accountFile: URL = {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/striga-account.data")
    }()

    // MARK: - Initializer

    public init() {
        
        // migration
        Task {
            await migrate()
        }
    }
    
    // MARK: - Migration

    private func migrate() {
        // Migration
        let migrationKey = "StrigaLocalProviderImpl.migration10"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            clear()
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }
}

extension StrigaLocalProviderImpl: StrigaLocalProvider {

    public func getCachedRegistrationData() -> StrigaUserDetailsResponse? {
        return get(from: registrationFile)
    }

    public func save(registrationData: StrigaUserDetailsResponse) async throws {
        try await save(model: registrationData, in: registrationFile)
    }

    public func getCachedUserData() async -> UserData? {
        return get(from: accountFile)
    }

    public func save(userData: UserData) async throws {
        try await save(model: userData, in: accountFile)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: registrationFile)
        try? FileManager.default.removeItem(at: accountFile)
    }

    // MARK: - Helpers

    private func get<T: Decodable>(from file: URL) -> T? {
        guard let data = try? Data(contentsOf: file) else { return nil }
        let cachedData = (try? JSONDecoder().decode(T.self, from: data))
        return cachedData
    }

    private func save<T: Encodable>(model: T, in file: URL) async throws {
        let data = try JSONEncoder().encode(model)
        try data.write(to: file)
    }
}
