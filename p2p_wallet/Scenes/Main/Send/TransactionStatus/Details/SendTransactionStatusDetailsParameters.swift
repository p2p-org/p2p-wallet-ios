struct SendTransactionStatusDetailsParameters {
    let title: String
    let description: String
    let fee: String?

    init(title: String, description: String, fee: String? = nil) {
        self.title = title
        self.description = description
        self.fee = fee
    }

    static var unknown: Self {
        .init(
            title: L10n.somethingWentWrong,
            description: L10n.unknownError
        )
    }
}
