import Foundation

public struct SwapInfo {
    let routes: Routes
    let tokens: [String: TokenValue]
    let pools: Pools
    let programIds: ProgramIDS
    let tokenNames: [String: String] // [Mint: TokenName]
}
