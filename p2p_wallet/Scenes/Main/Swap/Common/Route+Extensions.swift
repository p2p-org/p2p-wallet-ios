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
    
    func priceDescription(
        bestOutAmount: UInt64,
        toTokenDecimals: Decimals,
        toTokenSymbol: String
    ) -> String? {
        guard let myOutAmount = UInt64(outAmount) else { return nil }
        if myOutAmount >= bestOutAmount {
            return L10n.bestPrice
        } else {
            return "-" + (bestOutAmount-myOutAmount)
                .convertToBalance(decimals: toTokenDecimals)
                .tokenAmountFormattedString(symbol: toTokenSymbol)
        }
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
