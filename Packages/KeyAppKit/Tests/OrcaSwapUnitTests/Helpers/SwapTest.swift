import Foundation

// MARK: - SwapTest
struct SwapTest: Codable {
    let comment: String?
    let endpoint: String
    let endpointAdditionalQuery: String?
    let seedPhrase, fromMint, toMint: String
    let sourceAddress: String
    let destinationAddress: String?
    let poolsPair: [RawPool]
    let inputAmount: Double
    let slippage: Double
}
