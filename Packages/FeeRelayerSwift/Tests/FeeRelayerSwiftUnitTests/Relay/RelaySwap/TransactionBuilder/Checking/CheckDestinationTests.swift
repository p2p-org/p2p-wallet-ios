//
//  CheckDestinationTests.swift
//  
//
//  Created by Chung Tran on 03/11/2022.
//

import XCTest
@testable import FeeRelayerSwift
@testable import SolanaSwift

final class CheckDestinationTests: XCTestCase {
    private var accountStorage: MockAccountStorage!
    var swapTransactionBuilder: SwapTransactionBuilderImpl!
    var account: SolanaSwift.Account { accountStorage.account! }
    
    override func setUp() async throws {
        accountStorage = try await .init()
    }
    
    override func tearDown() async throws {
        accountStorage = nil
        swapTransactionBuilder = nil
    }
    
    func testCheckDestinationWhenDestinationIsCreatedSPLToken() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 0),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let destinationAddress: PublicKey = "2Z2Pbn1bsqN4NSrf1JLC1JRGNchoCVwXqsfeF7zWYTnK"
        
        var env = SwapTransactionBuilderOutput()
        
        try await swapTransactionBuilder.checkDestination(
            owner: account,
            destinationMint: .usdcMint,
            destinationAddress: destinationAddress,
            recentBlockhash: blockhash,
            output: &env
        )
        
        XCTAssertEqual(env.instructions.count, 0)
        XCTAssertEqual(env.accountCreationFee, 0)
        XCTAssertNil(env.additionalTransaction)
        XCTAssertNil(env.destinationNewAccount)
        XCTAssertEqual(env.userDestinationTokenAccountAddress, destinationAddress)
    }
    
    func testCheckDestinationWhenDestinationIsNonCreatedSPLToken() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 1),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        var env = SwapTransactionBuilderOutput()
        
        try await swapTransactionBuilder.checkDestination(
            owner: account,
            destinationMint: .usdcMint,
            destinationAddress: nil,
            recentBlockhash: blockhash,
            output: &env
        )
        
        let decodedInstruction = try JSONEncoder().encode(env.instructions)
        let expectedDecodedInstruction = try JSONEncoder().encode([
            AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                mint:  .usdcMint,
                owner: account.publicKey,
                payer: .feePayerAddress
            )
        ])
        
        XCTAssertEqual(decodedInstruction, expectedDecodedInstruction)
        XCTAssertEqual(env.accountCreationFee, minimumTokenAccountBalance)
        XCTAssertNil(env.additionalTransaction)
        XCTAssertNil(env.destinationNewAccount)
        
        let associatedAddress = try PublicKey.associatedTokenAddress(
            walletAddress: account.publicKey,
            tokenMintAddress: .usdcMint
        )
        XCTAssertEqual(env.userDestinationTokenAccountAddress, associatedAddress)
    }
    
    func testCheckDestinationWhenDestinationIsNativeSOL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 2),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        var env = SwapTransactionBuilderOutput()
        
        try await swapTransactionBuilder.checkDestination(
            owner: account,
            destinationMint: .wrappedSOLMint,
            destinationAddress: account.publicKey,
            recentBlockhash: blockhash,
            output: &env
        )
        
        XCTAssertNotNil(env.destinationNewAccount)
        let decodedInstruction = try JSONEncoder().encode(env.instructions)
        let expectedInstructions = [
            SystemProgram.createAccountInstruction(
                from: .feePayerAddress,
                toNewPubkey: env.destinationNewAccount!.publicKey,
                lamports: minimumTokenAccountBalance,
                space: AccountInfo.BUFFER_LENGTH,
                programId: TokenProgram.id
            ),
            TokenProgram.initializeAccountInstruction(
                account: env.destinationNewAccount!.publicKey,
                mint:  .wrappedSOLMint,
                owner: account.publicKey
            )
        ]
        let expectedDecodedInstructions = try JSONEncoder().encode(expectedInstructions)
        
        XCTAssertEqual(decodedInstruction, expectedDecodedInstructions)
        XCTAssertEqual(env.accountCreationFee, minimumTokenAccountBalance)
        XCTAssertNil(env.additionalTransaction)
        XCTAssertEqual(env.userDestinationTokenAccountAddress, env.destinationNewAccount?.publicKey)
    }
    
    func testCheckDestinationSpecialCaseWhenSourceTokenIsNativeSOLAndDestinationIsNonCreatedSPL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysator(testCase: 3),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        let sourceWSOLNewAccount = try await Account(network: .mainnetBeta)
        var env = SwapTransactionBuilderOutput(
            sourceWSOLNewAccount: sourceWSOLNewAccount
        )
        
        try await swapTransactionBuilder.checkDestination(
            owner: account,
            destinationMint: .usdcMint,
            destinationAddress: nil,
            recentBlockhash: blockhash,
            output: &env
        )
        
        // create account instruction is moved to separated instruction
        XCTAssertEqual(env.instructions.count, 0)
        
        // additional transaction (on top) to create associated token is needed
        XCTAssertNotNil(env.additionalTransaction)
        
        let additionalTransactionInstructionsEncoded = try JSONEncoder().encode(env.additionalTransaction!.transaction.instructions)
        let expectedAdditionalTransactionInstructionsEncoded = try JSONEncoder().encode([
            try AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                mint:  .usdcMint,
                owner: account.publicKey,
                payer: .feePayerAddress
            )
        ])
        XCTAssertEqual(additionalTransactionInstructionsEncoded, expectedAdditionalTransactionInstructionsEncoded)
        
        // create account instruction is moved to separated instruction so fee == 0 in this instruction
        XCTAssertEqual(env.accountCreationFee, 0)
        XCTAssertNil(env.destinationNewAccount)
//
        let associatedAddress = try PublicKey.associatedTokenAddress(
            walletAddress: account.publicKey,
            tokenMintAddress: .usdcMint
        )
        XCTAssertEqual(env.userDestinationTokenAccountAddress, associatedAddress)
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
        switch testCase {
        case 0:
            return .splAccount(needsCreation: false)
        case 1:
            return .splAccount(needsCreation: true)
        case 2:
            return .wsolAccount
        case 3:
            return .splAccount(needsCreation: true)
        default:
            fatalError()
        }
    }
}
