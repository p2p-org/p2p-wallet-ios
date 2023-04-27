import Foundation
@testable import Jupiter

extension Route {
    static func route(marketInfos: [MarketInfo]) -> Self {
        .init(
            inAmount: "1000",
            outAmount: "1980",
            priceImpactPct: 0.1,
            marketInfos: marketInfos,
            amount: "1000",
            slippageBps: 100,
            otherAmountThreshold: "200",
            swapMode: "ExactOut",
            fees: Fees(
                signatureFee: 200,
                openOrdersDeposits: [4000, 5000, 6000],
                ataDeposits: [8000, 9000, 10000],
                totalFeeAndDeposits: 20000,
                minimumSOLForTransaction: 200000
            ),
            keyapp: KeyAppInfo(
                fee: "20",
                refundableFee: "10",
                _hash: "hash1"
            )
        )
    }
}

extension MarketInfo {
    static func marketInfo(
        index: Int,
        inputMint: String? = nil,
        outputMint: String? = nil
    ) -> Self {
        .init(
            id: "marketInfo\(index)",
            label: "Market Info \(index)",
            inputMint: inputMint ?? "inputMint\(index)",
            outputMint: outputMint ?? "outputMint\(index)",
            notEnoughLiquidity: false,
            inAmount: "300",
            outAmount: "400",
            priceImpactPct: 0.03,
            lpFee: PlatformFee(amount: "20", mint: "lpFeeMint\(index)", pct: 0.002),
            platformFee: PlatformFee(amount: "10", mint: "platformFeeMint\(index)", pct: 0.001)
        )
    }
}
