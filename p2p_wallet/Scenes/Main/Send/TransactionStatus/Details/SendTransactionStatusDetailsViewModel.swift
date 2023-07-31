import Combine

final class SendTransactionStatusDetailsViewModel: ObservableObject {
    let close = PassthroughSubject<Void, Never>()

    @Published var title: String = ""
    @Published var description: String = ""
    @Published var feeInfo: String?

    init(params: SendTransactionStatusDetailsParameters) {
        title = params.title
        description = params.description
        if let fee = params.fee {
            feeInfo = L10n.theFeeWasReservedSoYouWouldnTPayItAgainTheNextTimeYouCreatedATransactionOfTheSameType(fee)
        }
    }
}
