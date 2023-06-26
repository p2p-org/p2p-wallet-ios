import Foundation
import XCTest
@testable import FeeRelayerSwift
@testable import SolanaSwift
@testable import OrcaSwapSwift

final class TransitiveSwapTransactionBuilderWithNonCreatedTransitTokenTests: XCTestCase {
    var swapTransactionBuilder: SwapTransactionBuilderImpl!
    var accountStorage: SolanaAccountStorage!
    
    override func setUp() async throws {
        accountStorage = try await MockAccountStorage()
    }
    
    override func tearDown() async throws {
        swapTransactionBuilder = nil
        accountStorage = nil
    }

    func testBuildTransitiveSwapSOLToNonCreatedSPLToken() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(testCase: 0),
            destinationAnalysator: MockDestinationAnalysator(testCase: 0),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        // SOL -> BTC -> ETH
        let inputAmount: UInt64 = 100000000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.solBTC, .btcETH],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: accountStorage.account!.publicKey, mint: .wrappedSOLMint),
            destinationTokenMint: .ethMint,
            destinationTokenAddress: nil,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, minimumTokenAccountBalance) // WSOL
        
        XCTAssertEqual(output.transactions.count, 2)
        
        // - Create destination spl token address (ETH)
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
            .writable(publicKey: .ethAssociatedAddress, isSigner: false),
            .readonly(publicKey: .owner, isSigner: false),
            .readonly(publicKey: .ethMint, isSigner: false),
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
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 6) // transfer
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
        
        let transitTokenPublicKey = try RelayProgram.getTransitTokenAccountAddress(
            user: .owner,
            transitTokenMint: .btcMint,
            network: .mainnetBeta
        )
        
        XCTAssertEqual(swapTransaction.transaction.instructions[3], .init( // initialize wsol
            keys: [
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .readonly(publicKey: .btcMint, isSigner: false),
                .writable(publicKey: .owner, isSigner: true),
                .readonly(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.createTransitToken])
        )

        let transitMinAmountOut = try Pool.solBTC.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        let minAmountOut = try Pool.btcETH.getMinimumAmountOut(inputAmount: transitMinAmountOut!, slippage: slippage)
        let newWSOLAccount = swapTransaction.signers[1]
        
        XCTAssertEqual(swapTransaction.transaction.instructions[4], .init( // transitive swap
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: newWSOLAccount.publicKey, isSigner: false),
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .writable(publicKey: .ethAssociatedAddress, isSigner: false),
                
                .readonly(publicKey: .swapProgramId, isSigner: false),
                .readonly(publicKey: Pool.solBTC.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.solBTC.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.feeAccount.publicKey, isSigner: false),
                
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: Pool.btcETH.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.btcETH.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.feeAccount.publicKey, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transitiveSwap] + inputAmount.bytes + transitMinAmountOut!.bytes + minAmountOut!.bytes)
        )
        
        XCTAssertEqual(swapTransaction.transaction.instructions[5], .init( // close wsol
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.closeAccount.bytes)
        )
    }
    
    func testBuildTransitiveSwapSOLToCreatedSPLToken() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(testCase: 1),
            destinationAnalysator: MockDestinationAnalysator(testCase: 1),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        // SOL -> BTC -> ETH
        let inputAmount: UInt64 = 100000000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.solBTC, .btcETH],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: accountStorage.account!.publicKey, mint: .wrappedSOLMint),
            destinationTokenMint: .ethMint,
            destinationTokenAddress: .ethAssociatedAddress,
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
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 6) // transfer
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
        let transitTokenPublicKey = try RelayProgram.getTransitTokenAccountAddress(
            user: .owner,
            transitTokenMint: .btcMint,
            network: .mainnetBeta
        )
        
        XCTAssertEqual(swapTransaction.transaction.instructions[3], .init( // Create transit token account
            keys: [
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .readonly(publicKey: .btcMint, isSigner: false),
                .writable(publicKey: .owner, isSigner: true),
                .readonly(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.createTransitToken])
        )

        let transitMinAmountOut = try Pool.solBTC.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        let minAmountOut = try Pool.btcETH.getMinimumAmountOut(inputAmount: transitMinAmountOut!, slippage: slippage)
        let newWSOLAccount = swapTransaction.signers[1]
        
        XCTAssertEqual(swapTransaction.transaction.instructions[4], .init( // direct swap
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: newWSOLAccount.publicKey, isSigner: false),
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .writable(publicKey: .ethAssociatedAddress, isSigner: false),
                
                .readonly(publicKey: .swapProgramId, isSigner: false),
                .readonly(publicKey: Pool.solBTC.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.solBTC.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.feeAccount.publicKey, isSigner: false),
                
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: Pool.btcETH.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.btcETH.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.feeAccount.publicKey, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transitiveSwap] + inputAmount.bytes + transitMinAmountOut!.bytes + minAmountOut!.bytes)
        )
        
        XCTAssertEqual(swapTransaction.transaction.instructions[5], .init( // close wsol
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.closeAccount.bytes)
        )
    }
    
    func testBuildTransitiveSwapSPLToNonCreatedSPLToken() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(testCase: 2),
            destinationAnalysator: MockDestinationAnalysator(testCase: 2),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        // BTC -> SOL -> ETH
        let inputAmount: UInt64 = 100000000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.solBTC.reversed, .ethSOL.reversed],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: .btcAssociatedAddress, mint: .btcMint),
            destinationTokenMint: .ethMint,
            destinationTokenAddress: nil,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, 0) // No WSOL creation
        
        XCTAssertEqual(output.transactions.count, 1)
        
        // - Swap transaction
        let swapTransaction = output.transactions[0]
        XCTAssertEqual(swapTransaction.signers.count, 1) // owner only
        XCTAssertEqual(swapTransaction.signers[0], accountStorage.account)
        XCTAssertEqual(swapTransaction.expectedFee, .init(transaction: 10000, accountBalances: minimumTokenAccountBalance)) // payer's, owner's signatures + SPL account creation fee
        XCTAssertEqual(swapTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(swapTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 3)
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
        
        let transitTokenPublicKey = try RelayProgram.getTransitTokenAccountAddress(
            user: .owner,
            transitTokenMint: .wrappedSOLMint,
            network: .mainnetBeta
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[1], .init( // Create transit token account
            keys: [
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .writable(publicKey: .owner, isSigner: true),
                .readonly(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.createTransitToken])
        )
        
        // - - Transitve Swap instruction
        let transitMinAmountOut = try Pool.solBTC.reversed.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        let minAmountOut = try Pool.ethSOL.reversed.getMinimumAmountOut(inputAmount: transitMinAmountOut!, slippage: slippage)
        XCTAssertEqual(swapTransaction.transaction.instructions[2], .init(
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .writable(publicKey: .ethAssociatedAddress, isSigner: false),
                
                .readonly(publicKey: .swapProgramId, isSigner: false),
                .readonly(publicKey: Pool.solBTC.reversed.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.solBTC.reversed.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.reversed.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.reversed.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.reversed.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.reversed.feeAccount.publicKey, isSigner: false),
                
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: Pool.ethSOL.reversed.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.ethSOL.reversed.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.reversed.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.reversed.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.reversed.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.reversed.feeAccount.publicKey, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transitiveSwap] + inputAmount.bytes + transitMinAmountOut!.bytes + minAmountOut!.bytes)
        )
    }
    
    func testBuildTransitiveSwapSPLToCreatedSPLToken() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(testCase: 3),
            destinationAnalysator: MockDestinationAnalysator(testCase: 3),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        // BTC -> SOL -> ETH
        let inputAmount: UInt64 = 100000000000
        let slippage: Double = 0.1
        
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.solBTC.reversed, .ethSOL.reversed],
            inputAmount: inputAmount,
            slippage: slippage,
            sourceTokenAccount: .init(address: .btcAssociatedAddress, mint: .btcMint),
            destinationTokenMint: .ethMint,
            destinationTokenAddress: nil,
            blockhash: blockhash
        )
        
        XCTAssertEqual(output.additionalPaybackFee, 0) // No WSOL creation
        
        XCTAssertEqual(output.transactions.count, 1)
        
        // - Swap transaction
        let swapTransaction = output.transactions[0]
        XCTAssertEqual(swapTransaction.signers.count, 1) // owner only
        XCTAssertEqual(swapTransaction.signers[0], accountStorage.account)
        XCTAssertEqual(swapTransaction.expectedFee, .init(transaction: 10000, accountBalances: 0)) // payer's, owner's signatures + SPL account creation fee
        XCTAssertEqual(swapTransaction.transaction.feePayer, .feePayerAddress)
        XCTAssertEqual(swapTransaction.transaction.recentBlockhash, blockhash)
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 2)
        // - - Transitve Swap instruction
        let transitMinAmountOut = try Pool.solBTC.reversed.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        let minAmountOut = try Pool.ethSOL.reversed.getMinimumAmountOut(inputAmount: transitMinAmountOut!, slippage: slippage)
        let transitTokenPublicKey = try RelayProgram.getTransitTokenAccountAddress(
            user: .owner,
            transitTokenMint: .wrappedSOLMint,
            network: .mainnetBeta
        )
        
        XCTAssertEqual(swapTransaction.transaction.instructions[0], .init( // Create transit token account
            keys: [
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .readonly(publicKey: .wrappedSOLMint, isSigner: false),
                .writable(publicKey: .owner, isSigner: true),
                .readonly(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.createTransitToken])
        )
        
        XCTAssertEqual(swapTransaction.transaction.instructions[1], .init(
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .writable(publicKey: .ethAssociatedAddress, isSigner: false),
                
                .readonly(publicKey: .swapProgramId, isSigner: false),
                .readonly(publicKey: Pool.solBTC.reversed.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.solBTC.reversed.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.reversed.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.reversed.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.reversed.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.solBTC.reversed.feeAccount.publicKey, isSigner: false),
                
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: Pool.ethSOL.reversed.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.ethSOL.reversed.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.reversed.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.reversed.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.reversed.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.reversed.feeAccount.publicKey, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transitiveSwap] + inputAmount.bytes + transitMinAmountOut!.bytes + minAmountOut!.bytes)
        )
    }
    
    func testBuildTransitiveSwapToSOL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(testCase: 4),
            destinationAnalysator: MockDestinationAnalysator(testCase: 4),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let inputAmount: UInt64 = 1000000
        let slippage: Double = 0.1
        
        // BTC -> ETH -> SOL
        let output = try await swapTransactionBuilder.buildSwapTransaction(
            userAccount: accountStorage.account!,
            pools: [.btcETH, .ethSOL],
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
        XCTAssertEqual(swapTransaction.transaction.instructions.count, 6)

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
        
        // - - Transitve Swap instruction
        let transitMinAmountOut = try Pool.btcETH.getMinimumAmountOut(inputAmount: inputAmount, slippage: slippage)
        let minAmountOut = try Pool.ethSOL.getMinimumAmountOut(inputAmount: transitMinAmountOut!, slippage: slippage)
        let transitTokenPublicKey = try RelayProgram.getTransitTokenAccountAddress(
            user: .owner,
            transitTokenMint: .ethMint,
            network: .mainnetBeta
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[2], .init( // Create transit token account
            keys: [
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .readonly(publicKey: .ethMint, isSigner: false),
                .writable(publicKey: .owner, isSigner: true),
                .readonly(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .sysvarRent, isSigner: false),
                .readonly(publicKey: SystemProgram.id, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.createTransitToken])
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[3], .init(
            keys: [
                .writable(publicKey: .feePayerAddress, isSigner: true),
                .readonly(publicKey: TokenProgram.id, isSigner: false),
                .readonly(publicKey: .owner, isSigner: true),
                .writable(publicKey: .btcAssociatedAddress, isSigner: false),
                .writable(publicKey: transitTokenPublicKey, isSigner: false),
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: Pool.btcETH.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.btcETH.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.btcETH.feeAccount.publicKey, isSigner: false),
                
                .readonly(publicKey: .deprecatedSwapProgramId, isSigner: false),
                .readonly(publicKey: Pool.ethSOL.account.publicKey, isSigner: false),
                .readonly(publicKey: Pool.ethSOL.authority.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.tokenAccountA.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.tokenAccountB.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.poolTokenMint.publicKey, isSigner: false),
                .writable(publicKey: Pool.ethSOL.feeAccount.publicKey, isSigner: false)
            ],
            programId: RelayProgram.id(network: .mainnetBeta),
            data: [RelayProgram.Index.transitiveSwap] + inputAmount.bytes + transitMinAmountOut!.bytes + minAmountOut!.bytes)
        )
        
        XCTAssertEqual(swapTransaction.transaction.instructions[4], .init( // close wsol and receive rent exempt
            keys: [
                .writable(publicKey: swapTransaction.signers[1].publicKey, isSigner: false),
                .writable(publicKey: .owner, isSigner: false),
                .readonly(publicKey: .owner, isSigner: false)
            ],
            programId: TokenProgram.id,
            data: TokenProgram.Index.closeAccount.bytes)
        )
        XCTAssertEqual(swapTransaction.transaction.instructions[5], .init( // return the rent exempt to fee payer address
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
        case .ethMint where testCase == 0 || testCase == 2:
            return .splAccount(needsCreation: true)
        case .ethMint where testCase == 1 || testCase == 3:
            return .splAccount(needsCreation: false)
        case .wrappedSOLMint where testCase == 4:
            return .wsolAccount
        default:
            fatalError()
        }
    }
}

private class MockTransitTokenAccountManager: TransitTokenAccountManager {
    private let testCase: Int

    init(testCase: Int) {
        self.testCase = testCase
    }
    
    func getTransitToken(pools: OrcaSwapSwift.PoolsPair) throws -> FeeRelayerSwift.TokenAccount? {
        let mint: PublicKey
        switch testCase {
        case 0, 1:
            mint = .btcMint
        case 2, 3:
            mint = .wrappedSOLMint
        case 4:
            mint = .ethMint
        default:
            fatalError()
        }
        let address = try RelayProgram.getTransitTokenAccountAddress(
            user: .owner,
            transitTokenMint: mint,
            network: .mainnetBeta
        )
        return .init(address: address, mint: mint)
    }
    
    func checkIfNeedsCreateTransitTokenAccount(transitToken: FeeRelayerSwift.TokenAccount?) async throws -> Bool? {
        true
    }
}
