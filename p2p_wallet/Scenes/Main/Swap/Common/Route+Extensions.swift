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
    
    func chainDescription(tokensList: [Token]) -> String {
        toSymbols(tokensList: tokensList)?.compactMap {$0}.joined(separator: " -> ") ?? ""
    }
    
    func bestPriceDescription(bestPrice: UInt64?, tokenB: Token?) -> String? {
        guard let bestPrice, let myPrices = UInt64(outAmount) else { return nil }
        return myPrices >= bestPrice ?
            L10n.bestPrice:
            "-" + (bestPrice-myPrices)
                .convertToBalance(decimals: tokenB?.decimals ?? 0)
                .tokenAmountFormattedString(symbol: tokenB?.symbol ?? "")
    }
}

extension Route {
    public var id: String {
        marketInfos.map(\.id).joined()
    }
    
    var name: String {
        marketInfos.map(\.label).joined(separator: " + ")
    }
}
