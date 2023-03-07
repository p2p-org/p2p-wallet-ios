import Foundation
import Jupiter

struct SwapLogsInfo: Codable {
    let swapTransaction: String?
    let route: Route?
    let routeInSymbols: String?
    let amountFrom: Double
    let amountTo: Double
    let tokens: [TokenInfo]
    let errorLogs: [String]?
    let fees: Fees?
    let prices: [String: Double]?
    
    struct TokenInfo: Codable {
        let pubkey: String?
        let balance: Double?
        let symbol, mint: String
    }
    
    struct Fees: Codable {
        let networkFee: SwapFeeInfo?
        let accountCreationFee: SwapFeeInfo?
        let liquidityFee: [SwapFeeInfo]
    }
}
