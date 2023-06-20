import Foundation
import Combine

/// Object that manages deeplinking route
public protocol DeeplinkingRouteManager {
    
    /// Handle url from URIScheme
    func handleURIScheme(url: URL) -> Bool
    
    /// Handle url from UniversalLinks
    func handleUniversalLink(url: URL) -> Bool

    /// Get current active route from stack and mark as handled
    func getActiveRoute() -> Route?
}

/// Default implementation of `DeeplinkingRouteManager`
public final class DeeplinkingRouteManagerImpl: DeeplinkingRouteManager {

    // MARK: - Properties
    
    public var activeRoute: Route?

    // MARK: - Initializer

    public init() {}
    
    // MARK: - Methods

    public func handleURIScheme(url: URL) -> Bool {
        do {
            // get route from url
            let urlParser = try URLParser(url: url)
            let route = try urlParser.parseURIScheme()
            
            // accept route
            activeRoute = route
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    public func handleUniversalLink(url: URL) -> Bool {
        // get route from url
        do {
            let urlParser = try URLParser(url: url)
            let route = try urlParser.parseUniversalLink(from: url)
            
            // accept route
            activeRoute = route
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    public func getActiveRoute() -> Route? {
        let route = activeRoute
        activeRoute = nil
        return route
    }
}


