import Foundation

enum Environment {
    /// Local (testing on simulator).
    case debug

    /// Internal testing in firebase
    case test

    /// Release build or testflight testing.
    case release

    static var current: Environment {
        #if DEBUG
            return .debug
        #elseif TEST
            return .test
        #else
            return .release
        #endif
    }
}
