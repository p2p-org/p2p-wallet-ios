//
//  CheckClosingAccountTests.swift
//  
//
//  Created by Chung Tran on 06/11/2022.
//

import XCTest
import SolanaSwift
@testable import FeeRelayerSwift

final class CheckClosingAccountTests: XCTestCase {
    var swapTransactionBuilder: SwapTransactionBuilderImpl!
    
    override func setUp() async throws {
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
        swapTransactionBuilder = nil
    }
    
    func testClosingAccountWithSourceWSOL() async throws {
        let owner = try await Account(network: .mainnetBeta)
        let newWSOL = try await Account(network: .mainnetBeta)
        var env = SwapTransactionBuilderOutput(
            sourceWSOLNewAccount: newWSOL
        )
        
        try swapTransactionBuilder.checkClosingAccount(
            owner: owner.publicKey,
            feePayer: .feePayerAddress,
            destinationTokenMint: .btcMint,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            env: &env
        )
        
        XCTAssertEqual(env.instructions.count, 1)
        
        let closingInstruction = env.instructions[0]
        XCTAssertEqual(closingInstruction.keys[0], .writable(publicKey: newWSOL.publicKey, isSigner: false))
        XCTAssertEqual(closingInstruction.keys[1], .writable(publicKey: owner.publicKey, isSigner: false))
        XCTAssertEqual(closingInstruction.keys[2], .readonly(publicKey: owner.publicKey, isSigner: false))
        
        XCTAssertEqual(closingInstruction.programId, TokenProgram.id)
        XCTAssertEqual(closingInstruction.data, [UInt8]([9]))
    }
    
    func testSignersWithDestinationWSOL() async throws {
        let owner = try await Account(network: .mainnetBeta)
        let newWSOL = try await Account(network: .mainnetBeta)
        var env = SwapTransactionBuilderOutput(
            destinationNewAccount: newWSOL,
            accountCreationFee: minimumTokenAccountBalance
        )
        
        try swapTransactionBuilder.checkClosingAccount(
            owner: owner.publicKey,
            feePayer: .feePayerAddress,
            destinationTokenMint: .wrappedSOLMint,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            env: &env
        )
        
        XCTAssertEqual(env.instructions.count, 2)
        
        let closingInstruction = env.instructions[0]
        
        XCTAssertEqual(closingInstruction.keys[0], .writable(publicKey: newWSOL.publicKey, isSigner: false))
        XCTAssertEqual(closingInstruction.keys[1], .writable(publicKey: owner.publicKey, isSigner: false))
        XCTAssertEqual(closingInstruction.keys[2], .readonly(publicKey: owner.publicKey, isSigner: false))
        
        XCTAssertEqual(closingInstruction.programId, TokenProgram.id)
        XCTAssertEqual(closingInstruction.data, [UInt8]([9]))
        
        let transferInstruction = env.instructions[1]
        
        XCTAssertEqual(transferInstruction.keys[0], .writable(publicKey: owner.publicKey, isSigner: true))
        XCTAssertEqual(transferInstruction.keys[1], .writable(publicKey: .feePayerAddress, isSigner: false))
        
        XCTAssertEqual(transferInstruction.programId, SystemProgram.id)
        XCTAssertEqual(transferInstruction.data, [UInt8]([2, 0, 0, 0, 240, 29, 31, 0, 0, 0, 0, 0]))
    }
}
