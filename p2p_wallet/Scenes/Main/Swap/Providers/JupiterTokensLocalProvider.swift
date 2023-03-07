import Jupiter
import SolanaSwift

protocol JupiterTokensProvider {
    func getCachedData() -> JupiterTokensCache?
    func save(tokens: [Token], routeMap: RouteMap) throws
    func clear()
}

struct JupiterTokensCache: Codable {
    let tokens: [Token]
    let routeMap: RouteMap
    let created: Date

    init(tokens: [Token], routeMap: RouteMap) {
        self.tokens = tokens
        self.routeMap = routeMap
        self.created = Date()
    }
}

final class JupiterInMemoryTokensProvider: JupiterTokensProvider {
    var cached: JupiterTokensCache?
    let locker = NSLock()
    
    func getCachedData() -> JupiterTokensCache? {
        locker.lock(); defer { locker.unlock() }
        return cached
    }
    
    func save(tokens: [SolanaSwift.Token], routeMap: Jupiter.RouteMap) throws {
        locker.lock(); defer { locker.unlock() }
        cached = .init(tokens: tokens, routeMap: routeMap)
    }
    
    func clear() {
        locker.lock(); defer { locker.unlock() }
        cached = nil
    }
}

//final class JupiterTokensLocalProvider: JupiterTokensProvider {
//
//    private let cacheFile: URL = {
//        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
//        let cacheDirectoryPath = arrayPaths[0]
//        return cacheDirectoryPath.appendingPathComponent("/jupiter-tokens.data")
//    }()
//
//    func getCachedData() -> JupiterTokensCache? {
//        guard let data = try? Data(contentsOf: cacheFile) else { return nil }
//        let cachedData = (try? JSONDecoder().decode(JupiterTokensCache.self, from: data))
//        if let createdDate = cachedData?.created, Date().timeIntervalSince(createdDate) < 86400 {
//            return cachedData
//        } else {
//            clear()
//            return nil
//        }
//    }
//
//    func save(tokens: [Token], routeMap: RouteMap) throws {
//        let data = try JSONEncoder().encode(JupiterTokensCache(tokens: tokens, routeMap: routeMap))
//        try data.write(to: cacheFile)
//    }
//
//    func clear() {
//        try? FileManager.default.removeItem(at: cacheFile)
//    }
//}
