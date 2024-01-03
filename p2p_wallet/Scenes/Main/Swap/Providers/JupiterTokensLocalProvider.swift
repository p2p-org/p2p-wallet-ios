import Foundation
import Jupiter
import SolanaSwift

protocol JupiterTokensProvider {
    func getCachedData() -> JupiterTokensCache?
    func save(tokens: [TokenMetadata], routeMap: RouteMap) throws
    func clear()
}

struct JupiterTokensCache: Codable {
    let tokens: [TokenMetadata]
    let routeMap: RouteMap
    let created: Date

    init(tokens: [TokenMetadata], routeMap: RouteMap) {
        self.tokens = tokens
        self.routeMap = routeMap
        created = Date()
    }
}

final class JupiterTokensLocalProvider: JupiterTokensProvider {
    private let cacheFile: URL = {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/jupiter-tokens.data")
    }()

    init() {
        migrate()
    }

    func getCachedData() -> JupiterTokensCache? {
        guard let data = try? Data(contentsOf: cacheFile) else { return nil }
        let cachedData = (try? JSONDecoder().decode(JupiterTokensCache.self, from: data))
        if let createdDate = cachedData?.created, Date().timeIntervalSince(createdDate) < 86400 {
            return cachedData
        } else {
            clear()
            return nil
        }
    }

    func save(tokens: [TokenMetadata], routeMap: RouteMap) throws {
        let data = try JSONEncoder().encode(JupiterTokensCache(tokens: tokens, routeMap: routeMap))
        try data.write(to: cacheFile)
    }

    func clear() {
        try? FileManager.default.removeItem(at: cacheFile)
    }

    // MARK: - Helpers

    private func migrate() {
        let migrationKey1 = "MigrationKey1"
        if !UserDefaults.standard.bool(forKey: migrationKey1) {
            clear()
            UserDefaults.standard.set(true, forKey: migrationKey1)
        }
    }
}
