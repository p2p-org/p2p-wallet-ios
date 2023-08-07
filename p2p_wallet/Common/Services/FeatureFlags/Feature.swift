import Foundation

public struct Feature: RawRepresentable, Hashable, Codable {
    private let name: String

    public var rawValue: String {
        name
    }

    public init(rawValue: String) {
        name = rawValue
    }
}
