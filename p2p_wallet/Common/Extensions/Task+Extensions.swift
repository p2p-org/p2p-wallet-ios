import Foundation

public extension Task where Success == Never, Failure == Never {
    static var isNotCancelled: Bool { !Task.isCancelled }
}
