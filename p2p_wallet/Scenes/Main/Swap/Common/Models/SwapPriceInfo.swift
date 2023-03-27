struct SwapPriceInfo: Equatable {
    let fromPrice: Double
    let toPrice: Double
    let relation: Double

    init(fromPrice: Double, toPrice: Double) {
        self.fromPrice = fromPrice
        self.toPrice = toPrice
        if fromPrice != 0 {
            self.relation = toPrice / fromPrice
        }
        else {
            self.relation = 0
        }
    }

    init(fromPrice: Double, toPrice: Double, relation: Double) {
        self.fromPrice = fromPrice
        self.toPrice = toPrice
        self.relation = relation
    }
}
