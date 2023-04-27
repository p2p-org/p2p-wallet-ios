//
//  JupiterSwapBusinessLogicHelperAutoSelectTokensTests.swift
//  
//
//  Created by Chung Tran on 18/03/2023.
//

import XCTest
@testable import Swap
import SolanaSwift

final class JupiterSwapBusinessLogicHelperAutoSelectTokensTests: XCTestCase {

    func testAutoSelectTokens_noWallets_returnsUsdcSol() throws {
        // Arrange
        let swapTokens: [SwapToken] = [
            .init(token: .usdc, userWallet: nil),
            .init(token: .nativeSolana, userWallet: nil),
        ]
        
        // Act
        let result = JupiterSwapBusinessLogicHelper.autoSelectTokens(swapTokens: swapTokens)
        
        // Assert
        XCTAssertEqual(result.fromToken.token, Token.usdc)
        XCTAssertEqual(result.toToken.token, Token.nativeSolana)
    }
    
    func testAutoSelectTokens_onlyUsdcWallet_returnsUsdcSol() throws {
        // Arrange
        let usdcWallet = Wallet(lamports: 100, token: .usdc)
        let swapTokens: [SwapToken] = [
            .init(token: .usdc, userWallet: usdcWallet),
            .init(token: .nativeSolana, userWallet: nil),
        ]
        
        // Act
        let result = JupiterSwapBusinessLogicHelper.autoSelectTokens(swapTokens: swapTokens)
        
        // Assert
        XCTAssertEqual(result.fromToken.token, Token.usdc)
        XCTAssertEqual(result.toToken.token, Token.nativeSolana)
    }
    
    func testAutoSelectTokens_onlySolWallet_returnsSolUsdc() throws {
        // Arrange
        let solWallet = Wallet(lamports: 100, token: .nativeSolana)
        let swapTokens: [SwapToken] = [
            .init(token: .usdc, userWallet: nil),
            .init(token: .nativeSolana, userWallet: solWallet),
        ]
        
        // Act
        let result = JupiterSwapBusinessLogicHelper.autoSelectTokens(swapTokens: swapTokens)
        
        // Assert
        XCTAssertEqual(result.fromToken.token, Token.nativeSolana)
        XCTAssertEqual(result.toToken.token, Token.usdc)
    }
    
    func testAutoSelectTokens_multipleWallets_returnsTokenWithHighestAmount() throws {
        // Arrange
        let usdtWallet = Wallet(lamports: 100, token: .usdt)
        let srmWallet = Wallet(lamports: 100, token: .srm)
        let solWallet = Wallet(lamports: 0, token: .nativeSolana)
        let swapTokens: [SwapToken] = [
            .init(token: .usdt, userWallet: usdtWallet),
            .init(token: .srm, userWallet: srmWallet),
            .init(token: .nativeSolana, userWallet: solWallet),
        ]
        
        // Act
        let result = JupiterSwapBusinessLogicHelper.autoSelectTokens(swapTokens: swapTokens)
        
        // Assert
        XCTAssertEqual(result.fromToken.token, Token.usdt)
        XCTAssertEqual(result.toToken.token, Token.nativeSolana)
    }

}
