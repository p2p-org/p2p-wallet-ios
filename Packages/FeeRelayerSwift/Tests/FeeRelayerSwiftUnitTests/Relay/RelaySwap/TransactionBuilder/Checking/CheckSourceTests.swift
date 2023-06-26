//
//  SwapTransactionBuilderTests.swift
//  
//
//  Created by Chung Tran on 03/11/2022.
//

import XCTest
@testable import FeeRelayerSwift
import SolanaSwift

final class CheckSourceTests: XCTestCase {
    var swapTransactionBuilder: SwapTransactionBuilderImpl!
    
    override func tearDown() async throws {
        swapTransactionBuilder = nil
    }
    
    func testCheckSourceWhenSwappingFromSPLToken() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        // source token is USDC (not native SOL)
        let originalUserSource: PublicKey = "HGeQ9fjhqKHeaSJr9pWBYSG1UWx3X9Jdx8nXX2immPDU"
        
        var env = SwapTransactionBuilderOutput(
            userSource: originalUserSource
        )
        
        try await swapTransactionBuilder.checkSource(
            owner: .owner,
            sourceMint: .usdcMint,
            inputAmount: 1000,
            output: &env
        )
        
        XCTAssertEqual(env.instructions.count, 0)
        XCTAssertEqual(env.userSource, originalUserSource)
        XCTAssertNil(env.sourceWSOLNewAccount)
    }
    
    func testCheckSourceWhenSwappingFromNativeSOL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        // source token is NativeSOL
        let inputAmount: UInt64 = 1000
        
        var env = SwapTransactionBuilderOutput(
            userSource: .owner
        )
        
        try await swapTransactionBuilder.checkSource(
            owner: .owner,
            sourceMint: .wrappedSOLMint,
            inputAmount: inputAmount,
            output: &env
        )
        
        let codedInstructions = try JSONEncoder().encode(env.instructions)
        let expectedCodedInstructions = try JSONEncoder().encode([
            SystemProgram.transferInstruction(
                from: .owner,
                to: .feePayerAddress,
                lamports: inputAmount
            ),
            SystemProgram.createAccountInstruction(
                from: .feePayerAddress,
                toNewPubkey: env.sourceWSOLNewAccount!.publicKey,
                lamports: minimumTokenAccountBalance + inputAmount,
                space: AccountInfo.BUFFER_LENGTH,
                programId: TokenProgram.id
            ),
            TokenProgram.initializeAccountInstruction(
                account: env.sourceWSOLNewAccount!.publicKey,
                mint: .wrappedSOLMint,
                owner: .owner
            )
        ])
        
        XCTAssertEqual(codedInstructions, expectedCodedInstructions)
        XCTAssertNotNil(env.sourceWSOLNewAccount)
        XCTAssertEqual(env.userSource, env.sourceWSOLNewAccount!.publicKey)
    }
    
    func testCheckSourceWhenSwappingFromSPLSOL() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManagerBase(),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        // source token is SPL SOL
        let originalUserSource: PublicKey = "HGeQ9fjhqKHeaSJr9pWBYSG1UWx3X9Jdx8nXX2immPDU"
        
        var env = SwapTransactionBuilderOutput(
            userSource: originalUserSource
        )
        
        try await swapTransactionBuilder.checkSource(
            owner: .owner,
            sourceMint: .wrappedSOLMint,
            inputAmount: 1000,
            output: &env
        )
        
        XCTAssertEqual(env.instructions.count, 0)
        XCTAssertEqual(env.userSource, originalUserSource)
        XCTAssertNil(env.sourceWSOLNewAccount)
    }

}
