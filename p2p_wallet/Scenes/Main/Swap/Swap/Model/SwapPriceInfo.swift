struct SwapPriceInfo {
    let fromPrice: Double
    let toPrice: Double
    let relation: Double

    init(fromPrice: Double, toPrice: Double) {
        self.fromPrice = fromPrice
        self.toPrice = toPrice
        if toPrice != 0 {
            self.relation = fromPrice / toPrice
        }
        else {
            self.relation = 0
        }
    }
}
