import XCTest
@testable import FeeRelayerSwift
@testable import OrcaSwapSwift
@testable import SolanaSwift

private let transitTokenSymbol = "USDC"
private let transitTokenMint: PublicKey = .usdcMint
private let transitTokenAccount: PublicKey = "JhhACrqV4LhpZY7ogW9Gy2MRLVanXXFxyiW548dsjBp"
private let owner: PublicKey = "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm"

final class TransitTokenAccountManagerTests: XCTestCase {
    var transitTokenAccountManager: TransitTokenAccountManagerImpl!
    
    func testGetTransitTokenMintPubkey() throws {
        transitTokenAccountManager = TransitTokenAccountManagerImpl(
            owner: owner,
            solanaAPIClient: MockSolanaAPIClient(testCase: 0),
            orcaSwap: MockOrcaSwap()
        )
        
        let mint = try transitTokenAccountManager.getTransitTokenMintPubkey(
            pools: [
                mockPool(tokenBName: transitTokenSymbol),
                mockPool(tokenBName: "ETH")
            ]
        )
        XCTAssertEqual(mint, transitTokenMint)
    }
    
    func testGetTransitToken() throws {
        transitTokenAccountManager = TransitTokenAccountManagerImpl(
            owner: owner,
            solanaAPIClient: MockSolanaAPIClient(testCase: 1),
            orcaSwap: MockOrcaSwap()
        )
        
        let transitToken = try transitTokenAccountManager.getTransitToken(
            pools: [
                mockPool(tokenBName: transitTokenSymbol),
                mockPool(tokenBName: "ETH")
            ]
        )
        XCTAssertEqual(transitToken?.address, transitTokenAccount)
        XCTAssertEqual(transitToken?.mint, .usdcMint)
    }
    
    func testCheckIfNeedsCreateTransitTokenAccount1() async throws {
        transitTokenAccountManager = TransitTokenAccountManagerImpl(
            owner: owner,
            solanaAPIClient: MockSolanaAPIClient(testCase: 2),
            orcaSwap: MockOrcaSwap()
        )
        
        let transitToken = FeeRelayerSwift.TokenAccount(
            address: transitTokenAccount,
            mint: transitTokenMint
        )
        let needsCreateTransitTokenAccount = try await transitTokenAccountManager
            .checkIfNeedsCreateTransitTokenAccount(
                transitToken: transitToken
            )
        XCTAssertEqual(needsCreateTransitTokenAccount, false)
    }
    
    func testCheckIfNeedsCreateTransitTokenAccount2() async throws {
        transitTokenAccountManager = TransitTokenAccountManagerImpl(
            owner: owner,
            solanaAPIClient: MockSolanaAPIClient(testCase: 3),
            orcaSwap: MockOrcaSwap()
        )
        
        let transitToken = FeeRelayerSwift.TokenAccount(
            address: transitTokenAccount,
            mint: transitTokenMint
        )
        let needsCreateTransitTokenAccount = try await transitTokenAccountManager
            .checkIfNeedsCreateTransitTokenAccount(
                transitToken: transitToken
            )
        XCTAssertEqual(needsCreateTransitTokenAccount, true)
    }
}

private class MockOrcaSwap: MockOrcaSwapBase {
    override func getMint(tokenName: String) -> String? {
        switch tokenName {
        case transitTokenSymbol:
            return transitTokenMint.base58EncodedString
        default:
            return nil
        }
    }
}

private func mockPool(tokenBName: String) -> Pool {
    .init(
        account: "",
        authority: "",
        nonce: 0,
        poolTokenMint: "",
        tokenAccountA: "",
        tokenAccountB: "",
        feeAccount: "",
        hostFeeAccount: nil,
        feeNumerator: 0,
        feeDenominator: 0,
        ownerTradeFeeNumerator: 0,
        ownerTradeFeeDenominator: 0,
        ownerWithdrawFeeNumerator: 0,
        ownerWithdrawFeeDenominator: 0,
        hostFeeNumerator: 0,
        hostFeeDenominator: 0,
        tokenAName: "",
        tokenBName: transitTokenSymbol,
        curveType: "",
        amp: nil,
        programVersion: nil,
        deprecated: nil
    )
}

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    private let testCase: Int
    
    init(testCase: Int) {
        self.testCase = testCase
        super.init()
    }
    
    override func getAccountInfo<T>(account: String) async throws -> BufferInfo<T>? where T : BufferLayout {
        switch account {
        case "JhhACrqV4LhpZY7ogW9Gy2MRLVanXXFxyiW548dsjBp" where testCase == 2:
            let info = BufferInfo<AccountInfo>(
                lamports: 0,
                owner: TokenProgram.id.base58EncodedString,
                data: .init(mint: transitTokenMint, owner: SystemProgram.id, lamports: 0, delegateOption: 0, isInitialized: true, isFrozen: true, state: 0, isNativeOption: 0, rentExemptReserve: nil, isNativeRaw: 0, isNative: true, delegatedAmount: 0, closeAuthorityOption: 0),
                executable: false,
                rentEpoch: 0
            )
            return info as? BufferInfo<T>
        case "JhhACrqV4LhpZY7ogW9Gy2MRLVanXXFxyiW548dsjBp" where testCase == 3:
            return nil
        default:
            return try await super.getAccountInfo(account: account)
        }
    }
}
