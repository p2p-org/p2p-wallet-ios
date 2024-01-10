import Foundation
import Jupiter
import SolanaSwift

extension QuoteResponse {
    func getMints() -> [String] {
        // get marketInfos
        guard !routePlan.isEmpty
        else {
            return []
        }
        // transform route to mints
        var mints = [String]()
        for (index, info) in routePlan.enumerated() {
            if index == 0 { mints.append(info.swapInfo.inputMint) }
            mints.append(info.swapInfo.outputMint)
        }
        return mints
    }

    func toSymbols(tokensList: [TokenMetadata]) -> [String]? {
        // get marketInfos
        guard !routePlan.isEmpty
        else {
            return nil
        }

        // transform mints to symbol
        return getMints()
            .map { mint in
                tokensList
                    .first(where: { $0.mintAddress == mint })?
                    .symbol ?? "UNKNOWN"
            }
    }

    func chainDescription(tokensList: [TokenMetadata]) -> String {
        toSymbols(tokensList: tokensList)?.compactMap { $0 }.joined(separator: " -> ") ?? ""
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
            return "-" + (bestOutAmount - myOutAmount)
                .convertToBalance(decimals: toTokenDecimals)
                .tokenAmountFormattedString(symbol: toTokenSymbol)
        }
    }
}

extension QuoteResponse {
    public var id: String {
        routePlan.map(\.swapInfo.ammKey).joined()
    }

    var name: String {
        routePlan.map(\.swapInfo.label).compactMap { $0 }.joined(separator: " x ")
    }
}
