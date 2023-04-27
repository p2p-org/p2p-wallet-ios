import Foundation
import SolanaSwift

public struct SwapToken: Equatable {
    public let token: Token
    public let userWallet: Wallet?
    
    public var address: String { token.address }
}
