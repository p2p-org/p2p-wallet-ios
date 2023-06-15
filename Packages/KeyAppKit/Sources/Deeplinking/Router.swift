import Foundation
import Combine

/// Object that manages deeplinking router
public protocol DeeplinkingRouter {
    /// Current active route
    var activeRoutePublisher: AnyPublisher<Route?, Never> { get }
    
    /// Handle url from URIScheme
    func handleURIScheme(url: URL) async throws
    
    /// Handle url from UniversalLinks
    func handleUniversalLink(url: URL) async throws
}

/// Default implementation of `DeeplinkingRouter`
public final actor Router: DeeplinkingRouter {

    // MARK: - Properties

    private let subject = CurrentValueSubject<Route?, Never>(nil)
    
    // MARK: - Computed properties

    public nonisolated var activeRoutePublisher: AnyPublisher<Route?, Never> {
        subject.eraseToAnyPublisher()
    }
    
    // MARK: - Methods

    public func handleURIScheme(url: URL) throws {
        // get route from url
        let urlParser = try URLParser(url: url)
        let route = try urlParser.parseURIScheme()
        
        // accept route
        subject.send(route)
    }
    
    public func handleUniversalLink(url: URL) async throws {
        // get route from url
        let urlParser = try URLParser(url: url)
        let route = try urlParser.parseUniversalLink(from: url)
        
        // accept route
        subject.send(route)
    }
}


