struct SwapTokenAmountInfo: Equatable {
    let amount: Double
    let token: String?
    
    var amountDescription: String? {
        amount.tokenAmountFormattedString(symbol: token ?? "")
    }
}
