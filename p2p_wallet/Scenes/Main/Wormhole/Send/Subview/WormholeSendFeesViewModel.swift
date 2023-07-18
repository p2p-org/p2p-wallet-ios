import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send

struct WormholeSendFees: Identifiable {
    var id: String { title }

    let title: String

    let subtitle: String

    let detail: String

    let isFree: Bool

    init?(title: String, subtitle: String?, detail: String?, isFree: Bool = false) {
        guard let subtitle else {
            return nil
        }

        self.title = title
        self.subtitle = subtitle
        self.detail = detail ?? ""
        self.isFree = isFree
    }
}

class WormholeSendFeesViewModel: BaseViewModel, ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager

    @Published var fees: [WormholeSendFees] = []

    var close = PassthroughSubject<Void, Never>()

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
                        subtitle: adapter.receive?.crypto,
                        detail: adapter.receive?.fiat
                    ),
                    .init(
                        title: L10n.usingWormholeBridge,
                        subtitle: adapter.arbiterFee?.crypto,
                        detail: adapter.arbiterFee?.fiat
                    ),
                    .init(
                        title: L10n.total,
                        subtitle: adapter.total?.crypto,
                        detail: adapter.total?.fiat
                    ),
                ].compactMap { $0 }
            }
            .store(in: &subscriptions)

        analyticsManager.log(event: .sendnewFreeTransactionClick(sendFlow: SendFlow.bridge.rawValue))
    }
}
