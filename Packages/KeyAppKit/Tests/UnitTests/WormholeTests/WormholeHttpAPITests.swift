@testable import Wormhole
import XCTest

final class WormholeHttpAPITests: XCTestCase {
    func testGetEthereumBundleStatus() async throws {
        let api = WormholeRPCAPI(endpoint: "https://bridge-service.key.app")
        let result = try await api.getEthereumBundleStatus(bundleID: "4VXmF7CsZV9CuPPqQ5zLVnou8UF5y9T7gCTtGmt9WMPP")
        
        print(result)
    }
}
