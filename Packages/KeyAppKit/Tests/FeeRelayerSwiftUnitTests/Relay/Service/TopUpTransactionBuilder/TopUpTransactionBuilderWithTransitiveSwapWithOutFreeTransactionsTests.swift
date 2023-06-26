import Foundation
import XCTest
@testable import FeeRelayerSwift
@testable import SolanaSwift
@testable import OrcaSwapSwift

private let transitToken = TokenAccount(address: "E4WiTThe5vWiQEqzUGvtgTfWZnUoxaLxprumwfhhttuf", mint: .usdtMint)

final class TopUpTransactionBuilderWithTransitiveSwapWithOutFreeTransactionsTests: XCTestCase {
    var builder: TopUpTransactionBuilder?
    let topUpPools = [Pool.usdcUSDT, Pool.solUSDT.reversed]
    let sourceToken = TokenAccount(
        address: .usdcAssociatedAddress,
        mint: .usdcMint
    )
    
    let targetAmount: Lamports = minimumTokenAccountBalance + minimumRelayAccountBalance
    
    override func tearDown() async throws {
        builder = nil
    }
    
    func testTopUpTransactionBuilderWhenRelayAccountIsNotYetCreatedAndTransitTokenIsNotYetCreated() async throws {
        builder = TopUpTransactionBuilderImpl(
            solanaApiClient: MockSolanaAPIClient(testCase: 0),
            orcaSwap: MockOrcaSwapBase(),
            account: try await MockAccountStorage().account!
        )
        
        let transaction1 = try await builder?.buildTopUpTransaction(
            context: getContext(
                relayAccountStatus: .notYetCreated
            ),
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        let expectedAmountIn: UInt64 = 75705
        let transitAmount: UInt64 = 73280
        // swap data
        let swapData = transaction1?.swapData as! TransitiveSwapData
        XCTAssertEqual(
            swapData,
            .init(
                from: .init(
                    programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                    accountPubkey: topUpPools[0].account,
                    authorityPubkey: topUpPools[0].authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: topUpPools[0].tokenAccountA,
                    destinationPubkey: topUpPools[0].tokenAccountB,
                    poolTokenMintPubkey: topUpPools[0].poolTokenMint,
                    poolFeeAccountPubkey: topUpPools[0].feeAccount,
                    amountIn: expectedAmountIn,
                    minimumAmountOut: transitAmount
                ),
                to: .init(
                    programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                    accountPubkey: topUpPools[1].account,
                    authorityPubkey: topUpPools[1].authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: topUpPools[1].tokenAccountA,
                    destinationPubkey: topUpPools[1].tokenAccountB,
                    poolTokenMintPubkey: topUpPools[1].poolTokenMint,
                    poolFeeAccountPubkey: topUpPools[1].feeAccount,
                    amountIn: transitAmount,
                    minimumAmountOut: targetAmount
                ),
                transitTokenMintPubkey: PublicKey.usdtMint.base58EncodedString,
                needsCreateTransitTokenAccount: true
            )
        )
        
        // prepared transaction
        let transaction = transaction1?.preparedTransaction.transaction
        let expectedFee = transaction1?.preparedTransaction.expectedFee

        XCTAssertEqual(transaction?.instructions.count, 4)

        // - Create relay account instruction
        let createRelayAccountInstruction = transaction!.instructions[0]
        XCTAssertEqual(createRelayAccountInstruction, .init(
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false)
            ],
            programId: SystemProgram.id,
            data: SystemProgram.Index.transfer.bytes + minimumRelayAccountBalance.bytes
        ))
        
        // - Create transit account instruction
        let createTransitAccountInstruction = transaction!.instructions[1]
        XCTAssertEqual(createTransitAccountInstruction, .init(
            keys: [
                .writable(publicKey: transitToken.address, isSigner: false),
                .readonly(publicKey: transitToken.mint, isSigner: false),
                .writable(publicKey: .owner, isSigner: true),
                .readonly(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: RelayProgram.Index.createTransitToken.bytes
        ))

        // - Top up swap instruction
        let topUpSwapInstruction = transaction!.instructions[2]
        XCTAssertEqual(topUpSwapInstruction, .init(
            keys: [
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: sourceToken.address, isSigner: false),
                .writable(publicKey: transitToken.address, isSigner: false),
                .writable(publicKey: .relayTemporaryWSOLAccount, isSigner: false),
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[0].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[0].authority.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[1].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[1].authority.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.topUpWithTransitiveSwap] + expectedAmountIn.bytes + transitAmount.bytes + targetAmount.bytes
        ))

        // - Relay transfer SOL instruction
        let relayTransferSOLInstruction = transaction!.instructions[3]
        XCTAssertEqual(relayTransferSOLInstruction, .init(
            keys: [
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false),
                .writable(publicKey: .feePayerAddress, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transferSOL] + expectedFee!.total.bytes
        ))

        XCTAssertEqual(
            expectedFee?.total,
            2 * lamportsPerSignature + minimumRelayAccountBalance + minimumTokenAccountBalance
        )
    }
    
    func testTopUpTransactionBuilderWhenRelayAccountIsNotYetCreatedAndTransitTokenIsCreated() async throws {
        builder = TopUpTransactionBuilderImpl(
            solanaApiClient: MockSolanaAPIClient(testCase: 1),
            orcaSwap: MockOrcaSwapBase(),
            account: try await MockAccountStorage().account!
        )
        
        let transaction1 = try await builder?.buildTopUpTransaction(
            context: getContext(
                relayAccountStatus: .notYetCreated
            ),
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        let expectedAmountIn: UInt64 = 75705
        let transitAmount: UInt64 = 73280
        // swap data
        let swapData = transaction1?.swapData as! TransitiveSwapData
        XCTAssertEqual(
            swapData,
            .init(
                from: .init(
                    programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                    accountPubkey: topUpPools[0].account,
                    authorityPubkey: topUpPools[0].authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: topUpPools[0].tokenAccountA,
                    destinationPubkey: topUpPools[0].tokenAccountB,
                    poolTokenMintPubkey: topUpPools[0].poolTokenMint,
                    poolFeeAccountPubkey: topUpPools[0].feeAccount,
                    amountIn: expectedAmountIn,
                    minimumAmountOut: transitAmount
                ),
                to: .init(
                    programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                    accountPubkey: topUpPools[1].account,
                    authorityPubkey: topUpPools[1].authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: topUpPools[1].tokenAccountA,
                    destinationPubkey: topUpPools[1].tokenAccountB,
                    poolTokenMintPubkey: topUpPools[1].poolTokenMint,
                    poolFeeAccountPubkey: topUpPools[1].feeAccount,
                    amountIn: transitAmount,
                    minimumAmountOut: targetAmount
                ),
                transitTokenMintPubkey: PublicKey.usdtMint.base58EncodedString,
                needsCreateTransitTokenAccount: false
            )
        )
        
        // prepared transaction
        let transaction = transaction1?.preparedTransaction.transaction
        let expectedFee = transaction1?.preparedTransaction.expectedFee

        XCTAssertEqual(transaction?.instructions.count, 3)

        // - Create relay account instruction
        let createRelayAccountInstruction = transaction!.instructions[0]
        XCTAssertEqual(createRelayAccountInstruction, .init(
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false)
            ],
            programId: SystemProgram.id,
            data: SystemProgram.Index.transfer.bytes + minimumRelayAccountBalance.bytes
        ))

        // - Top up swap instruction
        let topUpSwapInstruction = transaction!.instructions[1]
        XCTAssertEqual(topUpSwapInstruction, .init(
            keys: [
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: sourceToken.address, isSigner: false),
                .writable(publicKey: transitToken.address, isSigner: false),
                .writable(publicKey: .relayTemporaryWSOLAccount, isSigner: false),
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[0].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[0].authority.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[1].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[1].authority.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.topUpWithTransitiveSwap] + expectedAmountIn.bytes + transitAmount.bytes + targetAmount.bytes
        ))

        // - Relay transfer SOL instruction
        let relayTransferSOLInstruction = transaction!.instructions[2]
        XCTAssertEqual(relayTransferSOLInstruction, .init(
            keys: [
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false),
                .writable(publicKey: .feePayerAddress, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transferSOL] + expectedFee!.total.bytes
        ))

        XCTAssertEqual(
            expectedFee?.total,
            2 * lamportsPerSignature + minimumRelayAccountBalance + minimumTokenAccountBalance
        )
    }
    
    func testTopUpTransactionBuilderWhenRelayAccountIsCreatedAndTransitTokenIsNotYetCreated() async throws {
        builder = TopUpTransactionBuilderImpl(
            solanaApiClient: MockSolanaAPIClient(testCase: 2),
            orcaSwap: MockOrcaSwapBase(),
            account: try await MockAccountStorage().account!
        )
        
        let transaction1 = try await builder?.buildTopUpTransaction(
            context: getContext(
                relayAccountStatus: .created(balance: .random(in: minimumRelayAccountBalance..<minimumRelayAccountBalance+10000))
            ),
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        let expectedAmountIn: UInt64 = 75705
        let transitAmount: UInt64 = 73280
        // swap data
        let swapData = transaction1?.swapData as! TransitiveSwapData
        XCTAssertEqual(
            swapData,
            .init(
                from: .init(
                    programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                    accountPubkey: topUpPools[0].account,
                    authorityPubkey: topUpPools[0].authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: topUpPools[0].tokenAccountA,
                    destinationPubkey: topUpPools[0].tokenAccountB,
                    poolTokenMintPubkey: topUpPools[0].poolTokenMint,
                    poolFeeAccountPubkey: topUpPools[0].feeAccount,
                    amountIn: expectedAmountIn,
                    minimumAmountOut: transitAmount
                ),
                to: .init(
                    programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                    accountPubkey: topUpPools[1].account,
                    authorityPubkey: topUpPools[1].authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: topUpPools[1].tokenAccountA,
                    destinationPubkey: topUpPools[1].tokenAccountB,
                    poolTokenMintPubkey: topUpPools[1].poolTokenMint,
                    poolFeeAccountPubkey: topUpPools[1].feeAccount,
                    amountIn: transitAmount,
                    minimumAmountOut: targetAmount
                ),
                transitTokenMintPubkey: PublicKey.usdtMint.base58EncodedString,
                needsCreateTransitTokenAccount: true
            )
        )
        
        // prepared transaction
        let transaction = transaction1?.preparedTransaction.transaction
        let expectedFee = transaction1?.preparedTransaction.expectedFee

        XCTAssertEqual(transaction?.instructions.count, 3)
        
        // - Create transit account instruction
        let createTransitAccountInstruction = transaction!.instructions[0]
        XCTAssertEqual(createTransitAccountInstruction, .init(
            keys: [
                .writable(publicKey: transitToken.address, isSigner: false),
                .readonly(publicKey: transitToken.mint, isSigner: false),
                .writable(publicKey: .owner, isSigner: true),
                .readonly(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: RelayProgram.Index.createTransitToken.bytes
        ))

        // - Top up swap instruction
        let topUpSwapInstruction = transaction!.instructions[1]
        XCTAssertEqual(topUpSwapInstruction, .init(
            keys: [
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: sourceToken.address, isSigner: false),
                .writable(publicKey: transitToken.address, isSigner: false),
                .writable(publicKey: .relayTemporaryWSOLAccount, isSigner: false),
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[0].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[0].authority.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[1].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[1].authority.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.topUpWithTransitiveSwap] + expectedAmountIn.bytes + transitAmount.bytes + targetAmount.bytes
        ))

        // - Relay transfer SOL instruction
        let relayTransferSOLInstruction = transaction!.instructions[2]
        XCTAssertEqual(relayTransferSOLInstruction, .init(
            keys: [
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false),
                .writable(publicKey: .feePayerAddress, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transferSOL] + expectedFee!.total.bytes
        ))

        XCTAssertEqual(
            expectedFee?.total,
            2 * lamportsPerSignature + minimumTokenAccountBalance
        )
    }
    
    func testTopUpTransactionBuilderWhenRelayAccountIsCreatedAndTransitTokenIsCreated() async throws {
        builder = TopUpTransactionBuilderImpl(
            solanaApiClient: MockSolanaAPIClient(testCase: 3),
            orcaSwap: MockOrcaSwapBase(),
            account: try await MockAccountStorage().account!
        )
        
        let transaction1 = try await builder?.buildTopUpTransaction(
            context: getContext(
                relayAccountStatus: .created(balance: .random(in: minimumRelayAccountBalance..<minimumRelayAccountBalance+10000))
            ),
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        let expectedAmountIn: UInt64 = 75705
        let transitAmount: UInt64 = 73280
        // swap data
        let swapData = transaction1?.swapData as! TransitiveSwapData
        XCTAssertEqual(
            swapData,
            .init(
                from: .init(
                    programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                    accountPubkey: topUpPools[0].account,
                    authorityPubkey: topUpPools[0].authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: topUpPools[0].tokenAccountA,
                    destinationPubkey: topUpPools[0].tokenAccountB,
                    poolTokenMintPubkey: topUpPools[0].poolTokenMint,
                    poolFeeAccountPubkey: topUpPools[0].feeAccount,
                    amountIn: expectedAmountIn,
                    minimumAmountOut: transitAmount
                ),
                to: .init(
                    programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                    accountPubkey: topUpPools[1].account,
                    authorityPubkey: topUpPools[1].authority,
                    transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                    sourcePubkey: topUpPools[1].tokenAccountA,
                    destinationPubkey: topUpPools[1].tokenAccountB,
                    poolTokenMintPubkey: topUpPools[1].poolTokenMint,
                    poolFeeAccountPubkey: topUpPools[1].feeAccount,
                    amountIn: transitAmount,
                    minimumAmountOut: targetAmount
                ),
                transitTokenMintPubkey: PublicKey.usdtMint.base58EncodedString,
                needsCreateTransitTokenAccount: false
            )
        )
        
        // prepared transaction
        let transaction = transaction1?.preparedTransaction.transaction
        let expectedFee = transaction1?.preparedTransaction.expectedFee

        XCTAssertEqual(transaction?.instructions.count, 2)

        // - Top up swap instruction
        let topUpSwapInstruction = transaction!.instructions[0]
        XCTAssertEqual(topUpSwapInstruction, .init(
            keys: [
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: sourceToken.address, isSigner: false),
                .writable(publicKey: transitToken.address, isSigner: false),
                .writable(publicKey: .relayTemporaryWSOLAccount, isSigner: false),
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[0].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[0].authority.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[1].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[1].authority.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[1].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.topUpWithTransitiveSwap] + expectedAmountIn.bytes + transitAmount.bytes + targetAmount.bytes
        ))

        // - Relay transfer SOL instruction
        let relayTransferSOLInstruction = transaction!.instructions[1]
        XCTAssertEqual(relayTransferSOLInstruction, .init(
            keys: [
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .relayAccount, isSigner: false),
                .writable(publicKey: .feePayerAddress, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transferSOL] + expectedFee!.total.bytes
        ))

        XCTAssertEqual(
            expectedFee?.total,
            2 * lamportsPerSignature + minimumTokenAccountBalance
        )
    }
    
    // MARK: - Helpers

    private func getContext(
        relayAccountStatus: RelayAccountStatus
    ) -> RelayContext {
        .init(
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            minimumRelayAccountBalance: minimumRelayAccountBalance,
            feePayerAddress: .feePayerAddress,
            lamportsPerSignature: lamportsPerSignature,
            relayAccountStatus: relayAccountStatus,
            usageStatus: .init(
                maxUsage: 100,
                currentUsage: 100,
                maxAmount: 10000000,
                amountUsed: 10000000,
                reachedLimitLinkCreation: true
            )
        )
    }
}

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    private let testCase: Int
    
    init(testCase: Int) {
        self.testCase = testCase
        super.init()
    }
    
    override func getAccountInfo<T>(account: String) async throws -> BufferInfo<T>? where T : BufferLayout {
        switch account {
        case transitToken.address.base58EncodedString: // transit token
            switch testCase {
            case 0, 2:
                return nil
            case 1, 3:
                let info = BufferInfo<AccountInfo>(
                    lamports: 0,
                    owner: TokenProgram.id.base58EncodedString,
                    data: .init(mint: transitToken.mint, owner: SystemProgram.id, lamports: 0, delegateOption: 0, isInitialized: true, isFrozen: true, state: 0, isNativeOption: 0, rentExemptReserve: nil, isNativeRaw: 0, isNative: true, delegatedAmount: 0, closeAuthorityOption: 0),
                    executable: false,
                    rentEpoch: 0
                )
                return info as? BufferInfo<T>
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }
}
