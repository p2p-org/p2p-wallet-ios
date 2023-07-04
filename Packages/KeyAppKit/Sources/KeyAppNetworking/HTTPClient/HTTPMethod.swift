import Foundation

/// A set of HTTP request methods to indicate the desired action to be performed for a given resource
public enum HTTPMethod: String {
    /// Deletes the specified resource
    case delete = "DELETE"
    /// Requests a representation of the specified resource, should only retrieve data.
    case get = "GET"
    /// Applies partial modifications to a resource.
    case patch = "PATCH"
    /// Submits an entity to the specified resource, often causing a change in state or side effects on the server
    case post = "POST"
    /// Replaces all current representations of the target resource with the request payload
    case put = "PUT"
}
