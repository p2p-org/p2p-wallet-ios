import Foundation
import Combine

/// Object that manages deeplinking router
public protocol DeeplinkingRouter {
    /// Current active route
    var activeRoutePublisher: AnyPublisher<Route?, Never> { get }
    
    /// Handle url from URIScheme
    func handleURIScheme(url: URL) -> Bool
    
    /// Handle url from UniversalLinks
    func handleUniversalLink(url: URL) -> Bool
    
    // TODO: - Fix later
    /// Mark route as handled
    func markAsHandled()
}

/// Default implementation of `DeeplinkingRouter`
public final class Router: DeeplinkingRouter {

    // MARK: - Properties

    private let subject = CurrentValueSubject<Route?, Never>(nil)
    
    // MARK: - Computed properties

    public var activeRoutePublisher: AnyPublisher<Route?, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - Initializer

    public init() {}
    
    // MARK: - Methods

    public func handleURIScheme(url: URL) -> Bool {
        do {
            // get route from url
            let urlParser = try URLParser(url: url)
            let route = try urlParser.parseURIScheme()
            
            // accept route
            subject.send(route)
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
            subject.send(route)
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    public func markAsHandled() {
        subject.send(nil)
    }
}


