//
//  CheckTransitTokenAccountTests.swift
//  
//
//  Created by Chung Tran on 04/11/2022.
//

import XCTest
@testable import FeeRelayerSwift
@testable import OrcaSwapSwift
@testable import SolanaSwift

final class CheckTransitTokenAccountTests: XCTestCase {
    var swapTransactionBuilder: SwapTransactionBuilderImpl!
    
    override func tearDown() async throws {
        swapTransactionBuilder = nil
    }

    func testDirectSwapWithNoTransitTokenAccount() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(testCase: 0),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        var env = SwapTransactionBuilderOutput()
        
        try await swapTransactionBuilder.checkTransitTokenAccount(
            owner: .owner,
            poolsPair: [.solBTC],
            output: &env
        )
        
        XCTAssertNil(env.needsCreateTransitTokenAccount)
        XCTAssertNil(env.transitTokenMintPubkey)
        XCTAssertNil(env.transitTokenAccountAddress)
    }
    
    func testTransitiveSwapWithNonCreatedTransitTokenAccount() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(testCase: 1),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        var env = SwapTransactionBuilderOutput()
        
        try await swapTransactionBuilder.checkTransitTokenAccount(
            owner: .owner,
            poolsPair: [.solBTC, .btcETH], // SOL -> BTC -> ETH
            output: &env
        )
        
        XCTAssertEqual(env.needsCreateTransitTokenAccount, true)
        XCTAssertEqual(env.transitTokenMintPubkey, .btcMint)
        XCTAssertEqual(env.transitTokenAccountAddress, .btcTransitTokenAccountAddress)
    }
    
    func testTransitiveSwapWithCreatedTransitTokenAccount() async throws {
        swapTransactionBuilder = .init(
            network: .mainnetBeta,
            transitTokenAccountManager: MockTransitTokenAccountManager(testCase: 2),
            destinationAnalysator: MockDestinationAnalysatorBase(),
            feePayerAddress: .feePayerAddress,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            lamportsPerSignature: lamportsPerSignature
        )
        
        var env = SwapTransactionBuilderOutput()
        
        try await swapTransactionBuilder.checkTransitTokenAccount(
            owner: .owner,
            poolsPair: [.solBTC, .btcETH], // SOL -> BTC -> ETH
            output: &env
        )
        
        XCTAssertEqual(env.needsCreateTransitTokenAccount, false)
        XCTAssertEqual(env.transitTokenMintPubkey, .btcMint)
        XCTAssertEqual(env.transitTokenAccountAddress, .btcTransitTokenAccountAddress)
    }
}

private class MockTransitTokenAccountManager: TransitTokenAccountManager {
    let testCase: Int

    init(testCase: Int) {
        self.testCase = testCase
    }
    
    func getTransitToken(pools: OrcaSwapSwift.PoolsPair) throws -> FeeRelayerSwift.TokenAccount? {
        switch testCase {
        case 0:
            return nil
        default:
            return .init(address: .btcTransitTokenAccountAddress, mint: .btcMint)
        }
    }
    
    func checkIfNeedsCreateTransitTokenAccount(transitToken: FeeRelayerSwift.TokenAccount?) async throws -> Bool? {
        switch testCase {
        case 0:
            return nil
        case 1:
            return true
        case 2:
            return false
        default:
            fatalError()
        }
    }
}
