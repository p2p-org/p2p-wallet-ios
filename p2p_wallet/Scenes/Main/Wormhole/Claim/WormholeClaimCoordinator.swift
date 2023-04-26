import AnalyticsManager
import Foundation
import KeyAppKitCore
import Resolver
import SwiftUI
import Wormhole

enum WormholeClaimCoordinatorResult {
    case claiming(WormholeClaimUserAction)
}

class WormholeClaimCoordinator: SmartCoordinator<WormholeClaimCoordinatorResult> {
    @Injected private var analyticsManager: AnalyticsManager

    let account: EthereumAccount

    init(account: EthereumAccount, presentation: SmartCoordinatorPresentation) {
        self.account = account
        super.init(presentation: presentation)
        
        analyticsManager.log(event: .claimBridgesScreenOpen(from: "main"))
    }

    override func build() -> UIViewController {
        let vm = WormholeClaimViewModel(account: account)
        vm.action
            .sink { [weak self] action in
                guard let self = self else { return }
                switch action {
                case let .openFee(bundle):
                    self.coordinate(to: WormholeClaimFeeCoordinator(
                        account: self.account,
                        bundle: bundle,
                        presentation: SmartCoordinatorPresentPresentation(from: self.presentation)
                    ))
                    .sink { _ in }
                    .store(in: &self.subscriptions)
                case let .claiming(trx):
                    self.pop(.claiming(trx))
                case .openReceive:
                    self.coordinate(
                        to: ReceiveCoordinator(
                            network: .ethereum(
                                tokenSymbol: self.account.token.symbol,
                                tokenImage: {
                                    guard let url = self.account.token.logo else {
                                        return ReceiveNetwork.Image.image(.imageOutlineIcon)
                                    }
                                    return ReceiveNetwork.Image.url(url)
                                }()
                            ),
                            presentation: SmartCoordinatorPresentPresentation(from: self.presentation),
                            wrapIntoNavigation: true
                        )
                    )
                    .sink { _ in }
                    .store(in: &self.subscriptions)
                }
            }
            .store(in: &subscriptions)

        let view = WormholeClaimView(viewModel: vm)

        let vc = UIHostingController(rootView: view)
        vc.title = L10n.claim(account.token.symbol)
        vc.hidesBottomBarWhenPushed = true

        return vc
    }
}
