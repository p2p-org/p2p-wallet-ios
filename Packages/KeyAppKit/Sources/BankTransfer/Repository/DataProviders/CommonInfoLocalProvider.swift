import Foundation

public protocol CommonInfoLocalProvider {
    func getCommonInfo() async -> UserCommonInfo?
    func save(commonInfo: UserCommonInfo) async throws

    func clear() async
}

public actor CommonInfoLocalProviderImpl {

    private let cacheFile: URL = {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/bank-transfer-common.data")
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
        let migrationKey = "CommonInfoLocalProviderImpl.migration1"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            clear()
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }
}

extension CommonInfoLocalProviderImpl: CommonInfoLocalProvider {
    public func getCommonInfo() async -> UserCommonInfo? {
        guard let data = try? Data(contentsOf: cacheFile) else { return nil }
        let cachedData = (try? JSONDecoder().decode(UserCommonInfo.self, from: data))
        return cachedData
    }

    public func save(commonInfo: UserCommonInfo) async throws {
        let data = try JSONEncoder().encode(commonInfo)
        try data.write(to: cacheFile)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: cacheFile)
    }
}
