//
import Foundation

struct SwapSettingsRouteInfo: Identifiable, Equatable {
    init(id: String = UUID().uuidString, name: String, description: String, tokensChain: String) {
        self.id = id
        self.name = name
        self.description = description
        self.tokensChain = tokensChain
    }
    
    let id: String
    let name: String
    let description: String
    let tokensChain: String
}
