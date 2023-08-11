import Foundation
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift

protocol RawTransactionType {
    func createRequest() async throws -> String
    var mainDescription: String { get }
}

struct SwapMetaInfo {
    let swapMAX: Bool
    let swapUSD: Double
}

protocol SwapRawTransactionType: RawTransactionType {
    var sourceWallet: SolanaAccount { get }
    var destinationWallet: SolanaAccount { get }
    var fromAmount: Double { get }
    var toAmount: Double { get }
}
