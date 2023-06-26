import XCTest
@testable import OrcaSwapSwift
@testable import FeeRelayerSwift
import SolanaSwift

final class BuildSwapDataTests: XCTestCase {
    private var accountStorage: MockAccountStorage!
    var account: SolanaSwift.Account { accountStorage.account! }
    var swapTransactionBuilder: SwapTransactionBuilderImpl!
    
    override func setUp() async throws {
        accountStorage = try await .init()
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
    }
    
    override func tearDown() async throws {
        accountStorage = nil
        swapTransactionBuilder = nil
    }

    func testBuildDirectSwapData() async throws {
        // SOL -> BTC
        let swapData = try await swapTransactionBuilder.buildSwapData(
            userAccount: account,
            pools: [.solBTC],
            inputAmount: 10000,
            minAmountOut: 100,
            slippage: 0.01,
            needsCreateTransitTokenAccount: false
        )
        let encodedSwapData = try JSONEncoder().encode(swapData.swapData as! DirectSwapData)
        let expectedEncodedSwapData = try JSONEncoder().encode(
            DirectSwapData(
                programId: PublicKey.swapProgramId.base58EncodedString,
                accountPubkey: Pool.solBTC.account,
                authorityPubkey: Pool.solBTC.authority,
                transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                sourcePubkey: Pool.solBTC.tokenAccountA,
                destinationPubkey: Pool.solBTC.tokenAccountB,
                poolTokenMintPubkey: Pool.solBTC.poolTokenMint,
                poolFeeAccountPubkey: Pool.solBTC.feeAccount,
                amountIn: 10000,
                minimumAmountOut: 100
            )
        )
        XCTAssertEqual(encodedSwapData, expectedEncodedSwapData)
    }
    
    func testBuildTransitiveSwapData() async throws {
        // SOL -> BTC -> ETH
        let needsCreateTransitTokenAccount = Bool.random()
        
        let swapData = try await swapTransactionBuilder.buildSwapData(
            userAccount: account,
            pools: [.solBTC, .btcETH],
            inputAmount: 10000000,
            minAmountOut: nil,
            slippage: 0.01,
            transitTokenMintPubkey: .btcMint,
            needsCreateTransitTokenAccount: needsCreateTransitTokenAccount
        )
        let encodedSwapData = try JSONEncoder().encode(swapData.swapData as! TransitiveSwapData)
        let expectedEncodedSwapData = try JSONEncoder().encode(
            TransitiveSwapData(
                from: .init(
                    programId: PublicKey.swapProgramId.base58EncodedString,
                    accountPubkey: Pool.solBTC.account,
                    authorityPubkey: Pool.solBTC.authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: Pool.solBTC.tokenAccountA,
                    destinationPubkey: Pool.solBTC.tokenAccountB,
                    poolTokenMintPubkey: Pool.solBTC.poolTokenMint,
                    poolFeeAccountPubkey: Pool.solBTC.feeAccount,
                    amountIn: 10000000,
                    minimumAmountOut: 14
                ),
                to: .init(
                    programId: PublicKey.deprecatedSwapProgramId.base58EncodedString,
                    accountPubkey: Pool.btcETH.account,
                    authorityPubkey: Pool.btcETH.authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: Pool.btcETH.tokenAccountA,
                    destinationPubkey: Pool.btcETH.tokenAccountB,
                    poolTokenMintPubkey: Pool.btcETH.poolTokenMint,
                    poolFeeAccountPubkey: Pool.btcETH.feeAccount,
                    amountIn: 14,
                    minimumAmountOut: 171
                ),
                transitTokenMintPubkey: PublicKey.btcMint.base58EncodedString,
                needsCreateTransitTokenAccount: needsCreateTransitTokenAccount
            )
        )
        XCTAssertEqual(encodedSwapData, expectedEncodedSwapData)
    }
}
