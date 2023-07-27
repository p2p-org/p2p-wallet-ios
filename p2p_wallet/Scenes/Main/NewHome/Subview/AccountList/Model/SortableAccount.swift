import BigDecimal

protocol SortableAccount {
    var sortingKey: BigDecimal? { get }
}

extension SortableAccount {
    var sortingKey: BigDecimal? { nil }
}
