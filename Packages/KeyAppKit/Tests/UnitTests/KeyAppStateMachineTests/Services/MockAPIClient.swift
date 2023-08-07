import Foundation

protocol APIClient {
    func getData() async throws
}

class MockAPIClient: APIClient {
    var delayInMilliseconds: UInt64

    init(delayInMilliseconds: UInt64) {
        self.delayInMilliseconds = delayInMilliseconds
    }

    func getData() async throws {
        try await Task.sleep(nanoseconds: delayInMilliseconds * 1_000_000)
    }
}
