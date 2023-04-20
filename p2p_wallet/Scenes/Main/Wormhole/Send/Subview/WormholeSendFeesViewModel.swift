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

    init?(title: String, subtitle: String?, subtitleHighlighted: Bool = false, detail: String?) {
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
                        subtitle: adapter.networkFee?.crypto,
                        subtitleHighlighted: true,
                        detail: Double(adapter.networkFee?.fiat ?? "") == 0 ? L10n.paidByKeyApp : adapter.networkFee?.fiat
                    ),
                    .init(
                        title: L10n.usingWormholeBridge,
                        subtitle: adapter.bridgeFee?.crypto,
                        detail: adapter.bridgeFee?.fiat
                    ),
                ].compactMap { $0 }
            }
            .store(in: &subscriptions)
        
        analyticsManager.log(event: .sendnewFreeTransactionClick(source: SendSource.none.rawValue, sendFlow: "Bridge"))
    }
}
