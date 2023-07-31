import Foundation
import XCTest
@testable import FeeRelayerSwift
@testable import SolanaSwift
@testable import OrcaSwapSwift

final class TopUpTransactionBuilderWithDirectSwapTests: XCTestCase {
    var builder: TopUpTransactionBuilder?
    let topUpPools = [Pool.solUSDC.reversed]
    let sourceToken = TokenAccount(
        address: .usdcAssociatedAddress,
        mint: .usdcMint
    )
    
    let targetAmount: Lamports = minimumTokenAccountBalance + minimumRelayAccountBalance
    
    override func setUp() async throws {
        builder = TopUpTransactionBuilderImpl(
            solanaApiClient: MockSolanaAPIClientBase(),
            orcaSwap: MockOrcaSwapBase(),
            account: try await MockAccountStorage().account!
        )
    }
    
    override func tearDown() async throws {
        builder = nil
    }
    
    
    func testTopUpTransactionBuilderWhenFreeTransactionAvailableAndRelayAccountIsNotYetCreated() async throws {
        let transaction1 = try await builder?.buildTopUpTransaction(
            context: getContext(
                relayAccountStatus: .notYetCreated,
                usageStatus: .init(
                    maxUsage: 100,
                    currentUsage: 0,
                    maxAmount: 10000000,
                    amountUsed: 0,
                    reachedLimitLinkCreation: false
                )
            ),
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        let expectedAmountIn: UInt64 = 70250
        // swap data
        let swapData = transaction1?.swapData as! DirectSwapData
        XCTAssertEqual(
            swapData,
            .init(
                programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                accountPubkey: topUpPools[0].account,
                authorityPubkey: topUpPools[0].authority,
                transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                sourcePubkey: topUpPools[0].tokenAccountA,
                destinationPubkey: topUpPools[0].tokenAccountB,
                poolTokenMintPubkey: topUpPools[0].poolTokenMint,
                poolFeeAccountPubkey: topUpPools[0].feeAccount,
                amountIn: expectedAmountIn,
                minimumAmountOut: targetAmount
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
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[0].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[0].authority.publicKey, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .usdcAssociatedAddress, isSigner: false),
                .writable(publicKey: .relayTemporaryWSOLAccount, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.topUpWithDirectSwap] + expectedAmountIn.bytes + targetAmount.bytes
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
            minimumRelayAccountBalance + minimumTokenAccountBalance
        )
    }
    
    func testTopUpTransactionBuilderWhenFreeTransactionAvailableAndRelayAccountIsCreated() async throws {
        let transaction1 = try await builder?.buildTopUpTransaction(
            context: getContext(
                relayAccountStatus: .created(balance: .random(in: minimumRelayAccountBalance..<minimumRelayAccountBalance+1000)),
                usageStatus: .init(
                    maxUsage: 100,
                    currentUsage: 0,
                    maxAmount: 10000000,
                    amountUsed: 0,
                    reachedLimitLinkCreation: false
                )
            ),
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        let expectedAmountIn: UInt64 = 70250
        // swap data
        let swapData = transaction1?.swapData as! DirectSwapData
        XCTAssertEqual(
            swapData,
            .init(
                programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                accountPubkey: topUpPools[0].account,
                authorityPubkey: topUpPools[0].authority,
                transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                sourcePubkey: topUpPools[0].tokenAccountA,
                destinationPubkey: topUpPools[0].tokenAccountB,
                poolTokenMintPubkey: topUpPools[0].poolTokenMint,
                poolFeeAccountPubkey: topUpPools[0].feeAccount,
                amountIn: expectedAmountIn,
                minimumAmountOut: targetAmount
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
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[0].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[0].authority.publicKey, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .usdcAssociatedAddress, isSigner: false),
                .writable(publicKey: .relayTemporaryWSOLAccount, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.topUpWithDirectSwap] + expectedAmountIn.bytes + targetAmount.bytes
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
            minimumTokenAccountBalance
        )
    }
    
    func testTopUpTransactionBuilderWhenFreeTransactionIsNotAvailableAndRelayAccountIsNotYetCreated() async throws {
        let transaction1 = try await builder?.buildTopUpTransaction(
            context: getContext(
                relayAccountStatus: .notYetCreated,
                usageStatus: .init(
                    maxUsage: 100,
                    currentUsage: 100,
                    maxAmount: 10000000,
                    amountUsed: 0,
                    reachedLimitLinkCreation: true
                )
            ),
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        let expectedAmountIn: UInt64 = 70250
        // swap data
        let swapData = transaction1?.swapData as! DirectSwapData
        XCTAssertEqual(
            swapData,
            .init(
                programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                accountPubkey: topUpPools[0].account,
                authorityPubkey: topUpPools[0].authority,
                transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                sourcePubkey: topUpPools[0].tokenAccountA,
                destinationPubkey: topUpPools[0].tokenAccountB,
                poolTokenMintPubkey: topUpPools[0].poolTokenMint,
                poolFeeAccountPubkey: topUpPools[0].feeAccount,
                amountIn: expectedAmountIn,
                minimumAmountOut: targetAmount
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
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[0].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[0].authority.publicKey, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .usdcAssociatedAddress, isSigner: false),
                .writable(publicKey: .relayTemporaryWSOLAccount, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.topUpWithDirectSwap] + expectedAmountIn.bytes + targetAmount.bytes
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
    
    func testTopUpTransactionBuilderWhenFreeTransactionIsNotAvailableAndRelayAccountIsCreated() async throws {
        let transaction1 = try await builder?.buildTopUpTransaction(
            context: getContext(
                relayAccountStatus: .created(balance: .random(in: minimumRelayAccountBalance..<minimumRelayAccountBalance+1000)),
                usageStatus: .init(
                    maxUsage: 100,
                    currentUsage: 100,
                    maxAmount: 10000000,
                    amountUsed: 0,
                    reachedLimitLinkCreation: true
                )
            ),
            sourceToken: sourceToken,
            topUpPools: topUpPools,
            targetAmount: targetAmount,
            blockhash: blockhash
        )
        
        let expectedAmountIn: UInt64 = 70250
        // swap data
        let swapData = transaction1?.swapData as! DirectSwapData
        XCTAssertEqual(
            swapData,
            .init(
                programId: "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                accountPubkey: topUpPools[0].account,
                authorityPubkey: topUpPools[0].authority,
                transferAuthorityPubkey: PublicKey.owner.base58EncodedString,
                sourcePubkey: topUpPools[0].tokenAccountA,
                destinationPubkey: topUpPools[0].tokenAccountB,
                poolTokenMintPubkey: topUpPools[0].poolTokenMint,
                poolFeeAccountPubkey: topUpPools[0].feeAccount,
                amountIn: expectedAmountIn,
                minimumAmountOut: targetAmount
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
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: topUpPools[0].account.publicKey, isSigner: false),
                .readonly(publicKey: topUpPools[0].authority.publicKey, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .usdcAssociatedAddress, isSigner: false),
                .writable(publicKey: .relayTemporaryWSOLAccount, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: topUpPools[0].feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.topUpWithDirectSwap] + expectedAmountIn.bytes + targetAmount.bytes
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
        relayAccountStatus: RelayAccountStatus,
        usageStatus: UsageStatus
    ) -> RelayContext {
        .init(
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            minimumRelayAccountBalance: minimumRelayAccountBalance,
            feePayerAddress: .feePayerAddress,
            lamportsPerSignature: lamportsPerSignature,
            relayAccountStatus: relayAccountStatus,
            usageStatus: usageStatus
        )
    }
}
