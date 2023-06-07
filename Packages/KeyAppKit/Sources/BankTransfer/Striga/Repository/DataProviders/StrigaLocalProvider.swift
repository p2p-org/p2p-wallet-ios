import Foundation

public protocol StrigaLocalProvider {
    func getUserId() async -> String?
    func saveUserId(_ id: String) async
    
    func getCachedRegistrationData() async -> StrigaUserDetailsResponse?
    func save(registrationData: StrigaUserDetailsResponse) async throws
    
    func clearRegistrationData() async
}

public actor StrigaLocalProviderImpl {
    private let cacheFile: URL = {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/striga-registration.data")
    }()
    
    // Fix: temporary solution
    fileprivate let strigaUserIdUserDefaultsKey = "StrigaBankTransferLocalProvider.strigaUserIdUserDefaultsKey"

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
        let migrationKey = "StrigaLocalProviderImpl.migration9"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            clearRegistrationData()
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }
}

extension StrigaLocalProviderImpl: StrigaLocalProvider {
    public func getUserId() async -> String? {
        UserDefaults.standard.string(forKey: strigaUserIdUserDefaultsKey)
    }
    
    public func saveUserId(_ id: String) async {
        UserDefaults.standard.set(id, forKey: strigaUserIdUserDefaultsKey)
    }
    
    public func getCachedRegistrationData() -> StrigaUserDetailsResponse? {
        guard let data = try? Data(contentsOf: cacheFile) else { return nil }
        let cachedData = (try? JSONDecoder().decode(StrigaUserDetailsResponse.self, from: data))
        return cachedData
    }
    
    public func save(registrationData: StrigaUserDetailsResponse) throws {
        let data = try JSONEncoder().encode(registrationData)
        try data.write(to: cacheFile)
    }
    
    // TODO: Need to be cleared on log out
    public func clearRegistrationData() {
        UserDefaults.standard.set(nil, forKey: strigaUserIdUserDefaultsKey)
        try? FileManager.default.removeItem(at: cacheFile)
    }
}
