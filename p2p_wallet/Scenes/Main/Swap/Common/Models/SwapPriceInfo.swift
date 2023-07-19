struct SwapPriceInfo: Equatable {
    let fromPrice: Double
    let toPrice: Double
    let relation: Double

    init(fromPrice: Double, toPrice: Double, relation: Double) {
        self.fromPrice = fromPrice
        self.toPrice = toPrice
        self.relation = relation
    }
}
