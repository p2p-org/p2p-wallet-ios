import Combine

final class SendTransactionStatusDetailsViewModel: ObservableObject {

    let close = PassthroughSubject<Void, Never>()

    @Published var title: String = ""
    @Published var description: String = ""
    @Published var feeInfo: String?

    init(params: SendTransactionStatusDetailsParameters) {
        self.title = params.title
        self.description = params.description
        if let fee = params.fee {
            self.feeInfo = L10n.theFeeWasReservedSoYouWouldnTPayItAgainTheNextTimeYouCreatedATransactionOfTheSameType(fee)
        }
    }
}
