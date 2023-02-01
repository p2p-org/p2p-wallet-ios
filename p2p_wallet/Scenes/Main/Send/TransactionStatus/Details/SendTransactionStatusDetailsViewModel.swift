import Combine

struct SendTransactionStatusDetailsParameters {
    let title: String
    let description: String
    let fee: String?
}

final class SendTransactionStatusDetailsViewModel: ObservableObject {

    @Published var title: String = ""
    @Published var description: String = ""
    @Published var feeInfo: String?

    let closeAction: () -> Void

    init(params: SendTransactionStatusDetailsParameters, closeAction: @escaping () -> Void) {
        self.title = params.title
        self.description = params.description
        if let fee = params.fee {
            self.feeInfo = L10n.theFeeWasReservedSoYouWouldnTPayItAgainTheNextTimeYouCreatedATransactionOfTheSameType(fee)
        }
        self.closeAction = closeAction
    }
}
