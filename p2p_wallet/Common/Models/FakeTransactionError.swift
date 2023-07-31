import Foundation

enum FakeTransactionErrorType: String, CaseIterable, Identifiable {
    case noError
    case networkError
    case otherError
    var id: Self { self }
}

enum FakeTransactionError: Error {
    case random
}
