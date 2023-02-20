import Jupiter

protocol JupiterTokensProvider {
    func getCachedData() -> JupiterTokensCache?
    func save(tokens: [Jupiter.Token], routeMap: RouteMap) throws
    func clear()
}

struct JupiterTokensCache: Codable {
    let tokens: [Jupiter.Token]
    let routeMap: RouteMap
    let created: Date

    init(tokens: [Jupiter.Token], routeMap: RouteMap) {
        self.tokens = tokens
        self.routeMap = routeMap
        self.created = Date()
    }
}

final class JupiterTokensLocalProvider: JupiterTokensProvider {

    private let cacheFile: URL = {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/jupiter-tokens.data")
    }()

    func getCachedData() -> JupiterTokensCache? {
        guard let data = try? Data(contentsOf: cacheFile) else { return nil }
        let cachedData = (try? JSONDecoder().decode(JupiterTokensCache.self, from: data))
        if cachedData?.created.timeIntervalSince(Date()) < 86400 {
            return cachedData
        } else {
            clear()
            return nil
        }
    }

    func save(tokens: [Jupiter.Token], routeMap: RouteMap) throws {
        let data = try JSONEncoder().encode(JupiterTokensCache(tokens: tokens, routeMap: routeMap))
        try data.write(to: cacheFile)
    }

    func clear() {
        try? FileManager.default.removeItem(at: cacheFile)
    }
}
