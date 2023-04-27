import XCTest
@testable import Swap
import SolanaSwift

class JupiterSwapBusinessLogicHelperValidateAmountFromTests: XCTestCase {
    // MARK: - Other tokens
    
    // Test case where all parameters are valid
    func testValidParameters() {
        let fromTokenBalance: Lamports = 1000
        let amountFrom: Lamports = 500
        let fromTokenMint = "random"
        let minimumRentExemptForSOLAccount: Lamports = 100
        
        XCTAssertNoThrow(try JupiterSwapBusinessLogicHelper.validateFromAmounts(fromTokenBalance: fromTokenBalance, amountFrom: amountFrom, fromTokenMint: fromTokenMint, minimumRentExemptForSOLAccount: minimumRentExemptForSOLAccount))
    }
    
    // Test case where amountFrom is nil
    func testAmountFromIsNil() {
        let fromTokenBalance: Lamports = 1000
        let amountFrom: Lamports? = nil
        let fromTokenMint = "random"
        let minimumRentExemptForSOLAccount: Lamports = 100
        
        XCTAssertThrowsError(try JupiterSwapBusinessLogicHelper.validateFromAmounts(fromTokenBalance: fromTokenBalance, amountFrom: amountFrom, fromTokenMint: fromTokenMint, minimumRentExemptForSOLAccount: minimumRentExemptForSOLAccount)) { error in
            XCTAssertEqual(error as! JupiterSwapError, JupiterSwapError.amountFromIsZero)
        }
    }
    
    // Test case where user does not have enough balance
    func testNotEnoughFromToken() {
        let fromTokenBalance: Lamports = 1000
        let amountFrom: Lamports = 1500
        let fromTokenMint = "random"
        let minimumRentExemptForSOLAccount: Lamports = 100
        
        XCTAssertThrowsError(try JupiterSwapBusinessLogicHelper.validateFromAmounts(fromTokenBalance: fromTokenBalance, amountFrom: amountFrom, fromTokenMint: fromTokenMint, minimumRentExemptForSOLAccount: minimumRentExemptForSOLAccount)) { error in
            XCTAssertEqual(error as! JupiterSwapError, JupiterSwapError.notEnoughFromToken)
        }
    }
    
    // MARK: -  Validate native sol
    
    func testValidateNativeSOL() {
        // Test case 1: balance == amountFrom
        XCTAssertNoThrow(try JupiterSwapBusinessLogicHelper.validateNativeSOL(
            balance: 1000000,
            amountFrom: 1000000,
            minimumRentExemptForSOLAccount: 890880
        ))
        
        // Test case 2: remainingAfterTransaction == minimumRentExemptForSOLAccount
        XCTAssertNoThrow(try JupiterSwapBusinessLogicHelper.validateNativeSOL(
            balance: 1000000+890880,
            amountFrom: 1000000,
            minimumRentExemptForSOLAccount: 890880
        ))
        
        // Test case 3: remainingAfterTransaction > minimumRentExemptForSOLAccount
        XCTAssertNoThrow(try JupiterSwapBusinessLogicHelper.validateNativeSOL(
            balance: 1000000+890880+1,
            amountFrom: 1000000,
            minimumRentExemptForSOLAccount: 890880
        ))
        
        // Test case 4: remainingAfterTransaction < minimumRentExemptForSOLAccount
        XCTAssertThrowsError(try JupiterSwapBusinessLogicHelper.validateNativeSOL(
            balance: 1000000+131,
            amountFrom: 1000000,
            minimumRentExemptForSOLAccount: 890880
        )) { error in
            guard let jupiterSwapError = error as? JupiterSwapError else {
                XCTFail("Expected a JupiterSwapError")
                return
            }
            XCTAssertEqual(jupiterSwapError, JupiterSwapError.inputTooHigh(maxLamports: 109251))
        }
        
        // Test case 5: balance is smaller than minimumRentExemptForSOLAccount
        XCTAssertThrowsError(try JupiterSwapBusinessLogicHelper.validateNativeSOL(
            balance: 100000,
            amountFrom: 100000,
            minimumRentExemptForSOLAccount: 890880
        )) { error in
            guard let jupiterSwapError = error as? JupiterSwapError else {
                XCTFail("Expected a JupiterSwapError")
                return
            }
            XCTAssertEqual(jupiterSwapError, JupiterSwapError.notEnoughFromToken)
        }
    }

}


