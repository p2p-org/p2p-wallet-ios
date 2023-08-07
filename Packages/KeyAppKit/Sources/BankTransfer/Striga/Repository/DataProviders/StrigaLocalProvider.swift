import Foundation
import SolanaSwift

public protocol StrigaLocalProvider {
    func getCachedRegistrationData() async -> StrigaUserDetailsResponse?
    func save(registrationData: StrigaUserDetailsResponse) async throws

    func getCachedUserData() async -> UserData?
    func save(userData: UserData) async throws
    func getWhitelistedUserDestinations() async throws -> [StrigaWhitelistAddressResponse]
    func save(whitelisted: [StrigaWhitelistAddressResponse]) async throws

    func getCachedWithdrawalInfo() async -> StrigaWithdrawalInfo?
    func save(withdrawalInfo: StrigaWithdrawalInfo) async throws

    func clear() async
}

public actor StrigaLocalProviderImpl {
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
        let migrationKey = "StrigaLocalProviderImpl.migration13"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            clear()
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }
}

extension StrigaLocalProviderImpl: StrigaLocalProvider {
    public func getCachedWithdrawalInfo() async -> StrigaWithdrawalInfo? {
        get(from: cacheFileFor(.withdrawalInfo))
    }

    public func save(withdrawalInfo: StrigaWithdrawalInfo) async throws {
        try await save(model: withdrawalInfo, in: cacheFileFor(.withdrawalInfo))
    }

    public func getCachedRegistrationData() -> StrigaUserDetailsResponse? {
        get(from: cacheFileFor(.registration))
    }

    public func save(registrationData: StrigaUserDetailsResponse) async throws {
        try await save(model: registrationData, in: cacheFileFor(.registration))
    }

    public func getCachedUserData() async -> UserData? {
        get(from: cacheFileFor(.account))
    }

    public func save(userData: UserData) async throws {
        try await save(model: userData, in: cacheFileFor(.account))
    }

    public func getWhitelistedUserDestinations() async throws -> [StrigaWhitelistAddressResponse] {
        get(from: cacheFileFor(.whitelisted)) ?? []
    }

    public func save(whitelisted: [StrigaWhitelistAddressResponse]) async throws {
        try await save(model: whitelisted, in: cacheFileFor(.whitelisted))
    }

    public func clear() {
        for name in CacheFileName.allCases {
            try? FileManager.default.removeItem(at: cacheFileFor(name))
        }
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

    // Cache files

    enum CacheFileName: String, CaseIterable {
        case registration
        case account
        case whitelisted
        case withdrawalInfo
    }

    private func cacheFileFor(_ name: CacheFileName) -> URL {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/\(name).data")
    }
}
