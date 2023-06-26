//
//  DefaultSwapFeeRelayerCalculatorTests.swift
//  
//
//  Created by Chung Tran on 02/11/2022.
//

import XCTest
@testable import FeeRelayerSwift
@testable import OrcaSwapSwift
@testable import SolanaSwift

final class DefaultSwapFeeRelayerCalculatorTests: XCTestCase {

    var calculator: DefaultSwapFeeRelayerCalculator!
    
    override func tearDown() async throws {
        calculator = nil
    }
    
    // MARK: - Direct Swap

    func testCalculateDirectSwappingFeeFromSOLToNonCreatedSPL() async throws {
        // SOL -> New BTC
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 0),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 1,
            sourceTokenMint: "So11111111111111111111111111111111111111112",
            destinationTokenMint: .btcMint, // BTC
            destinationAddress: nil
        )
        
        XCTAssertEqual(
            fee.transaction,
            3 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            minimumTokenAccountBalance // fee for creating SPL Token Account
        )
    }
    
    func testCalculateDirectSwapingFeeFromSOLToCreatedSPL() async throws {
        // SOL -> BTC
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 1),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 1,
            sourceTokenMint: "So11111111111111111111111111111111111111112",
            destinationTokenMint: .btcMint, // BTC
            destinationAddress: .btcAssociatedAddress
        )
        
        XCTAssertEqual(
            fee.transaction,
            3 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            0 // account has already been created
        )
    }
    
    func testCalculateDirectSwapingFeeFromSPLToNonCreatedSPL() async throws {
        // BTC -> New ETH
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 2),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 1,
            sourceTokenMint: .btcMint,
            destinationTokenMint: .ethMint, // BTC
            destinationAddress: nil
        )
        
        XCTAssertEqual(
            fee.transaction,
            2 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            minimumTokenAccountBalance // fee for creating SPL Token Account
        )
    }
    
    func testCalculateDirectSwapingFeeFromSPLToCreatedSPL() async throws {
        // BTC -> New ETH
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 3),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 1,
            sourceTokenMint: .btcMint,
            destinationTokenMint: .ethMint, // BTC
            destinationAddress: .ethAssociatedAddress
        )
        
        XCTAssertEqual(
            fee.transaction,
            2 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            0 // account has already been created
        )
    }
    
    func testCalculateDirectSwapingFeeFromSPLToSOL() async throws {
        // BTC -> SOL
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 0),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 1,
            sourceTokenMint: .btcMint,
            destinationTokenMint: .wrappedSOLMint, // BTC
            destinationAddress: .owner
        )
        
        XCTAssertEqual(
            fee.transaction,
            3 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            0 // deposit fee has already been handled by fee relayer account
        )
    }
    
    // MARK: - Transitive Swap
    
    func testCalculateTransitiveSwappingFeeFromSOLToNonCreatedSPL() async throws {
        // SOL -> New BTC
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 4),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 2,
            sourceTokenMint: "So11111111111111111111111111111111111111112",
            destinationTokenMint: .btcMint, // BTC
            destinationAddress: nil
        )
        
        XCTAssertEqual(
            fee.transaction,
            5 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature, extra feepayer's and owner's signatures for additional transaction (2 transactions required)
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            minimumTokenAccountBalance // fee for creating SPL Token Account
        )
    }
    
    func testCalculateTransitiveSwapingFeeFromSOLToCreatedSPL() async throws {
        // SOL -> BTC
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 5),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 2,
            sourceTokenMint: "So11111111111111111111111111111111111111112",
            destinationTokenMint: .btcMint, // BTC
            destinationAddress: .btcAssociatedAddress
        )
        
        XCTAssertEqual(
            fee.transaction,
            3 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            0 // account has already been created
        )
    }
    
    func testCalculateTransitiveSwapingFeeFromSPLToNonCreatedSPL() async throws {
        // BTC -> New ETH
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 6),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 2,
            sourceTokenMint: .btcMint,
            destinationTokenMint: .ethMint, // BTC
            destinationAddress: nil
        )
        
        XCTAssertEqual(
            fee.transaction,
            2 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            minimumTokenAccountBalance // fee for creating SPL Token Account
        )
    }
    
    func testCalculateTransitiveSwapingFeeFromSPLToCreatedSPL() async throws {
        // BTC -> New ETH
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 7),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 2,
            sourceTokenMint: .btcMint,
            destinationTokenMint: .ethMint, // BTC
            destinationAddress: .ethAssociatedAddress
        )
        
        XCTAssertEqual(
            fee.transaction,
            2 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            0 // account has already been created
        )
    }
    
    func testCalculateTransitiveSwapingFeeFromSPLToSOL() async throws {
        // BTC -> SOL
        
        calculator = .init(
            destinationAnalysator: MockDestinationAnalysator(testCase: 0),
            accountStorage: try await MockAccountStorage()
        )
        
        let fee = try await calculator.calculateSwappingNetworkFees(
            lamportsPerSignature: lamportsPerSignature,
            minimumTokenAccountBalance: minimumTokenAccountBalance,
            swapPoolsCount: 2,
            sourceTokenMint: .btcMint,
            destinationTokenMint: .wrappedSOLMint, // BTC
            destinationAddress: .owner
        )
        
        XCTAssertEqual(
            fee.transaction,
            3 * lamportsPerSignature // feepayer's signature, owner's signature, new wsol's signature
        )
        
        XCTAssertEqual(
            fee.accountBalances,
            0 // deposit fee has already been handled by fee relayer account
        )
    }
}

private class MockDestinationAnalysator: DestinationAnalysator {
    private let testCase: Int

    init(testCase: Int = 0) {
        self.testCase = testCase
    }
    
    func analyseDestination(
        owner: PublicKey,
        mint: PublicKey
    ) async throws -> DestinationAnalysatorResult {
        switch mint {
        case .btcMint where testCase == 0 || testCase == 4:
            return .splAccount(needsCreation: true)
        case .btcMint where testCase == 1 || testCase == 5:
            return .splAccount(needsCreation: false)
        case .ethMint where testCase == 2 || testCase == 6:
            return .splAccount(needsCreation: true)
        case .ethMint where testCase == 3 || testCase == 7:
            return .splAccount(needsCreation: false)
        case .wrappedSOLMint:
            return .wsolAccount
        default:
            fatalError()
        }
    }
}
