import Foundation

@MainActor
class SolendTransactionDetailsViewModel: ObservableObject {
    var strategy: Strategy
    @Published var model: SolendTransactionDetailsView.Model?

    init(strategy: Strategy, model: SolendTransactionDetailsView.Model?) {
        self.strategy = strategy
        self.model = model
    }
}

extension SolendTransactionDetailsViewModel {
    enum Strategy {
        case deposit
        case withdraw
    }
}
