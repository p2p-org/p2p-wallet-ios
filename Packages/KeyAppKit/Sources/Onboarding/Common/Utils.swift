import Foundation

public typealias None = Void

public class Wrapper<T: Codable & Equatable>: Codable, Equatable {
    public internal(set) var value: T

    public init(_ value: T) { self.value = value }

    public static func == (lhs: Wrapper<T>, rhs: Wrapper<T>) -> Bool {
        lhs.value == rhs.value
    }
}
