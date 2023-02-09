struct SwapPriceInfo {
    let fromPrice: Double
    let toPrice: Double
    let relation: Double

    init(fromPrice: Double, toPrice: Double) {
        self.fromPrice = fromPrice
        self.toPrice = toPrice
        self.relation = fromPrice / toPrice
    }
}
