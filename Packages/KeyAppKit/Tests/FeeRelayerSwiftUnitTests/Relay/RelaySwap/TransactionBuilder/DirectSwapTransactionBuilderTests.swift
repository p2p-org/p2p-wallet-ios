import Foundation
import XCTest
@testable import FeeRelayerSwift
@testable import SolanaSwift
@testable import OrcaSwapSwift

final class DirectSwapTransactionBuilderTests: XCTestCase {
    var swapTransactionBuilder: SwapTransactionBuilderImpl!
    var accountStorage: SolanaAccountStorage!
    
    override func setUp() async throws {
        accountStorage = try await MockAccountStorage()
    }
    
    override func tearDown() async throws {
        swapTransactionBuilder = nil
        accountStorage = nil
    }
    
    func testBuildDirectSwapSOLToNonCreatedSPL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 0),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let inputAmount: UInt64 = 1000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.solBTC],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: accountStorage.account!.publicKey, mint: .wrappedSOLMint),
            destinationTokenMint: .btcMint,
            destinationTokenAddress: nil,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, minimumTokenAccountBalance) // WSOL
        // 2 transactions needed:
        XCTAssertEqual(output.transactions.count, 2)
        
        // - Create destination spl token address // TODO: - Also for direct swap or not???
        let createDestinationSPLTokenTransaction = output.transactions[0]
        XCTAssertEqual(createDestinationSPLTokenTransaction.signers, [accountStorage.account])
        XCTAssertEqual(createDestinationSPLTokenTransaction.expectedFee, .init(transaction: 10000, accountBalances: minimumTokenAccountBalance))
        XCTAssertEqual(createDestinationSPLTokenTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(createDestinationSPLTokenTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(createDestinationSPLTokenTransaction.transaction.instructions.count, 1)
        XCTAssertEqual(createDestinationSPLTokenTransaction.transaction.instructions[0].programId, AssociatedTokenProgram.id)
        XCTAssertEqual(createDestinationSPLTokenTransaction.transaction.instructions[0].data, [])
        XCTAssertEqual(createDestinationSPLTokenTransaction.transaction.instructions[0].keys, [
            .writable(publicKey: .feePayerAddress, isSigner: true),
            .writable(publicKey: .btcAssociatedAddress, isSigner: false),
            .readonly(publicKey: .owner, isSigner: false),
            .readonly(publicKey: .btcMint, isSigner: false),
            .readonly(publicKey: SystemProgram.id, isSigner: false),
            .readonly(publicKey: TokenProgram.id, isSigner: false),
            .readonly(publicKey: .sysvarRent, isSigner: false),
        ])
        
        // - Swap transaction
        let swapTransaction = output.transactions[1]
        XCTAssertEqual(swapTransaction.signers.count, 2) // owner / wsol new account
        XCTAssertEqual(swapTransaction.signers[0], accountStorage.account)
        XCTAssertEqual(swapTransaction.expectedFee, .init(transaction: 15000, accountBalances: 0)) // payer's, owner's, wsol's signatures
        XCTAssertEqual(swapTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(swapTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 5) // transfer
        // - - TransferSOL instruction
        XCTAssertEqual(swapTransaction.transaction.instructions[0], .init( // transfer inputAmount to fee relayer
            keys: [
                .writable(publicKey: .owner, isSigner: true),
                .writable(publicKey: .feePayerAddress, isSigner: false)
            ],
            programId: SystemProgram.id,
            data: SystemProgram.Index.transfer.bytes + inputAmount.bytes)
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[1], .init( // create wsol and transfer input amount + rent exempt
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: true)
            ],
            programId: SystemProgram.id,
            data: SystemProgram.Index.create.bytes + (inputAmount + minimumTokenAccountBalance).bytes + UInt64(165).bytes + TokenProgram.id.bytes)
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[2], .init( // initialize wsol
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.initializeAccount.bytes)
        )
        let minAmountOut = try Pool.solBTC.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        XCTAssertEqual(swapTransaction.transaction.instructions[3], .init( // direct swap
            keys: [
                .readonly(publicKey: Pool.solBTC.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.solBTC.authority.publicKey, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: Pool.solBTC.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false)
            ],
            programId: .swapProgramId,
            data: [UInt8(1)] + inputAmount.bytes + minAmountOut!.bytes)
        )
        
        XCTAssertEqual(swapTransaction.transaction.instructions[4], .init( // close wsol
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.closeAccount.bytes)
        )
    }
    
    func testBuildDirectSwapSOLToCreatedSPL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 1),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let inputAmount: UInt64 = 1000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.solBTC],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: accountStorage.account!.publicKey, mint: .wrappedSOLMint),
            destinationTokenMint: .btcMint,
            destinationTokenAddress: .btcAssociatedAddress,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, minimumTokenAccountBalance) // WSOL
        XCTAssertEqual(output.transactions.count, 1)
        // - Swap transaction
        let swapTransaction = output.transactions[0]
        XCTAssertEqual(swapTransaction.signers.count, 2) // owner / wsol new account
        XCTAssertEqual(swapTransaction.signers[0], accountStorage.account)
        XCTAssertEqual(swapTransaction.expectedFee, .init(transaction: 15000, accountBalances: 0)) // payer's, owner's, wsol's signatures
        XCTAssertEqual(swapTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(swapTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 5) // transfer
//        // - - TransferSOL instruction
        XCTAssertEqual(swapTransaction.transaction.instructions[0], .init( // transfer inputAmount to fee relayer
            keys: [
                .writable(publicKey: .owner, isSigner: true),
                .writable(publicKey: .feePayerAddress, isSigner: false)
            ],
            programId: SystemProgram.id,
            data: SystemProgram.Index.transfer.bytes + inputAmount.bytes)
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[1], .init( // create wsol and transfer input amount + rent exempt
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: true)
            ],
            programId: SystemProgram.id,
            data: SystemProgram.Index.create.bytes + (inputAmount + minimumTokenAccountBalance).bytes + UInt64(165).bytes + TokenProgram.id.bytes)
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[2], .init( // initialize wsol
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.initializeAccount.bytes)
        )
        let minAmountOut = try Pool.solBTC.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        XCTAssertEqual(swapTransaction.transaction.instructions[3], .init( // direct swap
            keys: [
                .readonly(publicKey: Pool.solBTC.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.solBTC.authority.publicKey, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: Pool.solBTC.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.feeAccount.publicKey, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false)
            ],
            programId: .swapProgramId,
            data: [UInt8(1)] + inputAmount.bytes + minAmountOut!.bytes)
        )

        XCTAssertEqual(swapTransaction.transaction.instructions[4], .init( // close wsol
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.closeAccount.bytes)
        )
    }
    
    func testBuildDirectSwapSPLToNonCreatedSPL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 2),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let inputAmount: UInt64 = 1000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.btcETH],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: .btcAssociatedAddress, mint: .btcMint),
            destinationTokenMint: .ethMint,
            destinationTokenAddress: nil,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, 0) // No Source WSOL created
        XCTAssertEqual(output.transactions.count, 1)
        // - Swap transaction
        let swapTransaction = output.transactions[0]
        XCTAssertEqual(swapTransaction.signers.count, 1) // owner only
        XCTAssertEqual(swapTransaction.signers[0], accountStorage.account)
        XCTAssertEqual(swapTransaction.expectedFee, .init(transaction: 10000, accountBalances: minimumTokenAccountBalance)) // payer's, owner's signatures + SPL account creation fee
        XCTAssertEqual(swapTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(swapTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 2) // transfer
        // - - Create Associated Token Account instruction
        XCTAssertEqual(swapTransaction.transaction.instructions[0], .init(
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .writable(publicKey: .ethAssociatedAddress, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .ethMint, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false)
            ],
            programId: AssociatedTokenProgram.id,
            data: [])
        )
        // - - Direct Swap instruction
        let minAmountOut = try Pool.btcETH.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        XCTAssertEqual(swapTransaction.transaction.instructions[1], .init(
            keys: [
                .readonly(publicKey: try PublicKey(string: Pool.btcETH.account), isSigner: false),
                .readonly(publicKey: try PublicKey(string: Pool.btcETH.authority), isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.tokenAccountA), isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.tokenAccountB), isSigner: false),
                .writable(publicKey: .ethAssociatedAddress, isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.poolTokenMint), isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.feeAccount), isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false)
            ],
            programId: .deprecatedSwapProgramId,
            data: [UInt8(1)] + inputAmount.bytes + minAmountOut!.bytes)
        )
    }
    
    func testBuildDirectSwapSPLToCreatedSPL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 3),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let inputAmount: UInt64 = 1000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.btcETH],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: .btcAssociatedAddress, mint: .btcMint),
            destinationTokenMint: .ethMint,
            destinationTokenAddress: .ethAssociatedAddress,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, 0) // No Source WSOL created
        XCTAssertEqual(output.transactions.count, 1)
        // - Swap transaction
        let swapTransaction = output.transactions[0]
        XCTAssertEqual(swapTransaction.signers.count, 1) // owner only
        XCTAssertEqual(swapTransaction.signers[0], accountStorage.account)
        XCTAssertEqual(swapTransaction.expectedFee, .init(transaction: 10000, accountBalances: 0)) // payer's, owner's signatures
        XCTAssertEqual(swapTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(swapTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 1) // transfer
        // - - Direct Swap instruction
        let minAmountOut = try Pool.btcETH.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        XCTAssertEqual(swapTransaction.transaction.instructions[0], .init(
            keys: [
                .readonly(publicKey: try PublicKey(string: Pool.btcETH.account), isSigner: false),
                .readonly(publicKey: try PublicKey(string: Pool.btcETH.authority), isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.tokenAccountA), isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.tokenAccountB), isSigner: false),
                .writable(publicKey: .ethAssociatedAddress, isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.poolTokenMint), isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.feeAccount), isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false)
            ],
            programId: .deprecatedSwapProgramId,
            data: [UInt8(1)] + inputAmount.bytes + minAmountOut!.bytes)
        )
    }
    
    func testBuildDirectSwapSPLToCreatedSPLEvenWhenUserDoesNotGiveDestinationSPLTokenAddress() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 4),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let inputAmount: UInt64 = 1000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.btcETH],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: .btcAssociatedAddress, mint: .btcMint),
            destinationTokenMint: .ethMint,
            destinationTokenAddress: nil,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, 0) // No Source WSOL created
        XCTAssertEqual(output.transactions.count, 1)
        // - Swap transaction
        let swapTransaction = output.transactions[0]
        XCTAssertEqual(swapTransaction.signers.count, 1) // owner only
        XCTAssertEqual(swapTransaction.signers[0], accountStorage.account)
        XCTAssertEqual(swapTransaction.expectedFee, .init(transaction: 10000, accountBalances: 0)) // payer's, owner's signatures
        XCTAssertEqual(swapTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(swapTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 1) // transfer
        // - - Direct Swap instruction
        let minAmountOut = try Pool.btcETH.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        XCTAssertEqual(swapTransaction.transaction.instructions[0], .init(
            keys: [
                .readonly(publicKey: try PublicKey(string: Pool.btcETH.account), isSigner: false),
                .readonly(publicKey: try PublicKey(string: Pool.btcETH.authority), isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.tokenAccountA), isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.tokenAccountB), isSigner: false),
                .writable(publicKey: .ethAssociatedAddress, isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.poolTokenMint), isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.btcETH.feeAccount), isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false)
            ],
            programId: .deprecatedSwapProgramId,
            data: [UInt8(1)] + inputAmount.bytes + minAmountOut!.bytes)
        )
    }
    
    func testBuildDirectSwapToSOL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 5),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let inputAmount: UInt64 = 1000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.solBTC.reversed],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: .btcAssociatedAddress, mint: .btcMint),
            destinationTokenMint: .wrappedSOLMint,
            destinationTokenAddress: .owner,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, 0) // No Source WSOL created
        XCTAssertEqual(output.transactions.count, 1)
        // - Swap transaction
        let swapTransaction = output.transactions[0]
        XCTAssertEqual(swapTransaction.signers.count, 2) // owner, destination wsol
        XCTAssertEqual(swapTransaction.signers[0], accountStorage.account)
        XCTAssertEqual(swapTransaction.expectedFee, .init(transaction: 15000, accountBalances: 0)) // payer's, owner's, destination wsol's signatures
        XCTAssertEqual(swapTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(swapTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 5) // transfer
        
        XCTAssertEqual(swapTransaction.transaction.instructions[0], .init( // create destination wsol
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: true)
            ],
            programId: SystemProgram.id,
            data: SystemProgram.Index.create.bytes + minimumTokenAccountBalance.bytes + UInt64(165).bytes + TokenProgram.id.bytes)
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[1], .init( // initialize wsol
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.initializeAccount.bytes)
        )
        // - - Direct Swap instruction
        let minAmountOut = try Pool.solBTC.reversed.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        XCTAssertEqual(swapTransaction.transaction.instructions[2], .init(
            keys: [
                .readonly(publicKey: try PublicKey(string: Pool.solBTC.reversed.account), isSigner: false),
                .readonly(publicKey: try PublicKey(string: Pool.solBTC.reversed.authority), isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.solBTC.reversed.tokenAccountA), isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.solBTC.reversed.tokenAccountB), isSigner: false),
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.solBTC.reversed.poolTokenMint), isSigner: false),
                .writable(publicKey: try PublicKey(string: Pool.solBTC.reversed.feeAccount), isSigner: false),
                .readonly(publicKey: TokenProgram.id, isSigner: false)
            ],
            programId: .swapProgramId,
            data: [UInt8(1)] + inputAmount.bytes + minAmountOut!.bytes)
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[3], .init( // close wsol and receive rent exempt
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.closeAccount.bytes)
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[4], .init( // return the rent exempt to fee payer address
            keys: [
                .writable(publicKey: .owner, isSigner: true),
                .writable(publicKey: .feePayerAddress, isSigner: false)
            ],
            programId: SystemProgram.id,
            data: SystemProgram.Index.transfer.bytes + minimumTokenAccountBalance.bytes)
        )
    }
}

private class MockDestinationAnalysator: DestinationAnalysator {
    private let testCase: Int

    init(testCase: Int) {
        self.testCase = testCase
    }
    
    func analyseDestination(
        owner: PublicKey,
        mint: PublicKey
    ) async throws -> DestinationAnalysatorResult {
        switch mint {
        // Case 0
        case .btcMint where testCase == 0:
            return .splAccount(needsCreation: true)
        case .btcMint where testCase == 1:
            return .splAccount(needsCreation: false)
        case .ethMint where testCase == 2:
            return .splAccount(needsCreation: true)
        case .ethMint where testCase == 3:
            return .splAccount(needsCreation: false)
        case .ethMint where testCase == 4:
            return .splAccount(needsCreation: false)
        case .wrappedSOLMint where testCase == 5:
            return .wsolAccount
        default:
            fatalError()
        }
    }
}

private class MockTransitTokenAccountManager: TransitTokenAccountManager {
    func getTransitToken(pools: OrcaSwapSwift.PoolsPair) throws -> FeeRelayerSwift.TokenAccount? {
        nil
    }
    
    func checkIfNeedsCreateTransitTokenAccount(transitToken: FeeRelayerSwift.TokenAccount?) async throws -> Bool? {
        nil
    }
}
