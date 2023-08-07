import SolanaSwift
import XCTest
@testable import FeeRelayerSwift

final class CheckSignersTests: XCTestCase {
    var swapTransactionBuilder: SwapTransactionBuilderImpl!

    override func tearDown() async throws {
        swapTransactionBuilder = nil
    }

    func testSignersWithSourceWSOL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )

        let owner = try await KeyPair(network: .mainnetBeta)
        let newWSOL = try await KeyPair(network: .mainnetBeta)
        var env = SwapTransactionBuilderOutput(
            sourceWSOLNewAccount: newWSOL
        )

        swapTransactionBuilder.checkSigners(
            ownerAccount: owner,
            env: &env
        )

        XCTAssertEqual(env.signers.first, owner)
        XCTAssertEqual(env.signers.last, newWSOL)
    }

    func testSignersWithDestinationWSOL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )

        let owner = try await KeyPair(network: .mainnetBeta)
        let newWSOL = try await KeyPair(network: .mainnetBeta)
        var env = SwapTransactionBuilderOutput(
            destinationNewAccount: newWSOL
        )

        swapTransactionBuilder.checkSigners(
            ownerAccount: owner,
            env: &env
        )

        XCTAssertEqual(env.signers.first, owner)
        XCTAssertEqual(env.signers.last, newWSOL)
    }
}
