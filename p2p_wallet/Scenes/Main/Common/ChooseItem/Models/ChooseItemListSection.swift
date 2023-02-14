struct ChooseItemListSection: Identifiable {
    let id = UUID()
    let items: [any ChooseItemSearchableItem]
}
