import Foundation
import PnLService

class MockPnLService: PnLService {
    var calledCount = 0

    func getPNL() async throws -> String {
        try await Task.sleep(nanoseconds: 300_000_000)
        calledCount += 1
        if (calledCount % 2) == 1 {
            throw NSError(domain: "Fake error", code: -1)
        }
        return "1%"
    }
}
