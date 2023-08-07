import Foundation

public struct RouteMap: Codable, Equatable {
    public let mintKeys: [String]
    public let indexesRouteMap: [String: [String]]

    public init(mintKeys: [String], indexesRouteMap: [String: [String]]) {
        self.mintKeys = mintKeys
        self.indexesRouteMap = indexesRouteMap
    }
}
