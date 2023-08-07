import FeeRelayerSwift
import Foundation
import SolanaSwift

class MockFeeRelayerAPIClientBase: FeeRelayerAPIClient {
    func feeTokenData(mint _: String) async throws -> FeeRelayerSwift.FeeTokenData {
        fatalError()
    }

    var version: Int = 0

    func getFeePayerPubkey() async throws -> String {
        PublicKey.feePayerAddress.base58EncodedString
    }

    func getFreeFeeLimits(for _: String) async throws -> FeeRelayerSwift.FeeLimitForAuthorityResponse {
        fatalError()
    }

    func requestFreeFeeLimits(for authority: String) async throws -> FeeRelayerSwift.FeeLimitForAuthorityResponse {
        try await getFreeFeeLimits(for: authority)
    }

    func sendTransaction(_: FeeRelayerSwift.RequestType) async throws -> String {
        fatalError()
    }
}
