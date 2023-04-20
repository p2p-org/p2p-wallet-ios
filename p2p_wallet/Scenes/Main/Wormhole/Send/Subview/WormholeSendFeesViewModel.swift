import AnalyticsManager
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send

struct WormholeSendFees: Identifiable {
    var id: String { title }

    let title: String

    let subtitle: String

    let subtitleHighlighted: Bool

    let detail: String

    let isFree: Bool

    init?(title: String, subtitle: String?, detail: String?, isFree: Bool = false) {
        guard let subtitle else {
            return nil
        }

        self.title = title
        self.subtitle = subtitle
        self.detail = detail ?? ""
        self.subtitleHighlighted = subtitleHighlighted
    }
}

class WormholeSendFeesViewModel: BaseViewModel, ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager

    @Published var loading: Bool = false
    @Published var fees: [WormholeSendFees] = []

    init(fees: [WormholeSendFees]) {
        self.fees = fees
    }

    init(
        stateMachine: WormholeSendInputStateMachine,
        ethereumTokensRepository _: EthereumTokensRepository = Resolver.resolve(),
        solanaTokensRepository _: SolanaTokensService = Resolver.resolve()
    ) {
        super.init()

        stateMachine
            .state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                let adapter = WormholeSendFeesAdapter(state: state)

                self?.fees = [
                    .init(title: L10n.recipientSAddress, subtitle: adapter.recipientAddress, detail: ""),
                    .init(
                        title: L10n.recipientGets,
                        subtitle: adapter.receive.crypto,
                        detail: adapter.receive.fiat
                    ),
                    .init(
                        title: L10n.networkFee,
                        subtitle: L10n.paidByKeyApp,
                        detail: L10n.free,
                        isFree: true
                    ),
                    .init(
                        title: "Arbiter fee",
                        subtitle: adapter.arbiterFee?.crypto,
                        detail: adapter.arbiterFee?.fiat
                    ),
                ].compactMap { $0 }
            }
            .store(in: &subscriptions)

        analyticsManager.log(event: .sendnewFreeTransactionClick(source: SendSource.none.rawValue, sendFlow: "Bridge"))
    }
}
