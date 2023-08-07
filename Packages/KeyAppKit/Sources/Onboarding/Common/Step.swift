import Foundation

public protocol Step {
    var step: Float { get }
}

public protocol Continuable {
    var continuable: Bool { get }
}
