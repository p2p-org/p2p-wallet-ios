import Foundation
import SolanaSwift

public enum JupiterSwapError: Swift.Error, Equatable {
    // Auto choose token
    case noNativeWalletFound
    
    case amountFromIsZero
    case fromAndToTokenAreEqual

    case notEnoughFromToken
    case inputTooHigh(maxLamports: Lamports) // FIXME: - NativeSOL case
}
