import Foundation
import SolanaSwift

extension JupiterSwapBusinessLogicHelper {
    public static func validateFromAmounts(
        fromTokenBalance: Lamports?,
        amountFrom: Lamports?,
        fromTokenMint: String,
        minimumRentExemptForSOLAccount: Lamports
    ) throws {
        // Check if amount from is not nil
        guard let amountFrom else {
            throw JupiterSwapError.amountFromIsZero
        }
        
        // Check if user has enough balance
        guard let fromTokenBalance, fromTokenBalance >= amountFrom else {
            throw JupiterSwapError.notEnoughFromToken
        }
        
        // Check for remaining SOL amount if fromToken is Solana
        if fromTokenMint == Token.nativeSolana.address {
            try validateNativeSOL(
                balance: fromTokenBalance,
                amountFrom: amountFrom,
                minimumRentExemptForSOLAccount: minimumRentExemptForSOLAccount
            )
        }
    }
    
    // MARK: - Helpers

    static func validateNativeSOL(
        balance: Lamports,
        amountFrom: Lamports,
        minimumRentExemptForSOLAccount: Lamports
    ) throws {
        // assert that balance >= amountFrom
        guard balance >= amountFrom, balance > minimumRentExemptForSOLAccount else {
            throw JupiterSwapError.notEnoughFromToken
        }
        
        // For native SOL account, user must either:
        
        // Spend all SOL left (amountFrom == balance)
        if balance == amountFrom {
            // all goods
            return
        }
        
        // Or keep at least minimumRentExemptForSOLAccount (890880 at the moment) in their account after transaction
        // Unless they receive error: transaction leaves an account with a lower balance than rent-exempt minimum
        
        // get remaining amount after transaction if it will be confirmed
        let remainingAfterTransaction = balance - amountFrom
        
        // if the remaining amount is greater than 0 and less than minimumSOLAccountLamports, throw an error
        if remainingAfterTransaction < minimumRentExemptForSOLAccount {
            // get max input that user can spend their SOL
            let maximumInput = (balance - minimumRentExemptForSOLAccount)
            
            throw JupiterSwapError.inputTooHigh(maxLamports: maximumInput)
        }
    }
}
