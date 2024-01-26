import Foundation
import PnLService

class MockPnLService: PnLService {
    func getPNL() async throws -> String {
        try await Task.sleep(nanoseconds: 3_000_000_000)
        return "1%"
    }
}
