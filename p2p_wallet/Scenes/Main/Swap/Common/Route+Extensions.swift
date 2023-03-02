import Foundation
import Jupiter
import SolanaSwift

extension Route {
    func toSymbols(tokensList: [Token]) -> [String]? {
        // get marketInfos
        guard !marketInfos.isEmpty
        else {
            return nil
        }
        
        // transform route to mints
        var mints = [String]()
        for (index, info) in marketInfos.enumerated() {
            if index == 0 { mints.append(info.inputMint) }
            mints.append(info.outputMint)
        }
        
        // transform mints to symbol
        return mints
            .map { mint in
                tokensList
                    .first(where: {$0.address == mint})?
                    .symbol ?? "UNKNOWN"
            }
    }
}

extension Route: SwapSettingsRouteInfo {
    public var id: String {
        marketInfos.map(\.id).joined()
    }
    
    var name: String {
        marketInfos.map(\.label).joined(separator: ", ")
    }
    
    var description: String {
        "Best price"
    }
    
    var tokens: String {
        (toSymbols(tokensList: []) ?? []).compactMap {$0}.joined(separator: " -> ")
    }
}
