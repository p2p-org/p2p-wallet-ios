import SolanaSwift
import SolanaToken

extension AccountBalance: ChooseItemSearchableItem {
    public var id: String { pubkey ?? "" }
    
    func matches(keyword: String) -> Bool {
        token.symbol.lowercased().hasPrefix(keyword.lowercased()) ||
            token.symbol.lowercased().contains(keyword.lowercased()) ||
            token.name.lowercased().hasPrefix(keyword.lowercased()) ||
            token.name.lowercased().contains(keyword.lowercased())
    }
}
