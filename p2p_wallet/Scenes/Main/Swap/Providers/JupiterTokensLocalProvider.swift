import Jupiter

protocol JupiterTokensProvider {
    func getTokens() -> [Jupiter.Token]?
    func save(tokens: [Jupiter.Token]?) throws
}

final class JupiterTokensLocalProvider: JupiterTokensProvider {

    private struct SwapWalletsCache: Codable {
        let tokens: [Token]
        let created: Date
    }

    private let cacheFile: URL = {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/jupiter-tokens.data")
    }()

    func getTokens() -> [Token]? {
        guard let data = try? Data(contentsOf: cacheFile) else { return nil }
        let cachedData = (try? JSONDecoder().decode(SwapWalletsCache.self, from: data))
        if cachedData?.created.timeIntervalSince(Date()) < 86400 {
            return cachedData?.tokens
        }
        return nil
    }

    func save(tokens: [Token]?) throws {
        if let tokens {
            let data = try JSONEncoder().encode(SwapWalletsCache(tokens: tokens, created: Date()))
            try data.write(to: cacheFile)
        } else {
            try? FileManager.default.removeItem(at: cacheFile)
        }
    }
}
