struct SwapTokenAmountInfo: Equatable {
    let amount: Double
    let token: String?
    
    var amountDescription: String? {
        amount > 0 ? amount.tokenAmountFormattedString(symbol: token ?? ""): nil
    }
}
