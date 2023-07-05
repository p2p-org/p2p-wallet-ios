import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeychainSwift
import Wormhole
import UIKit

class WormholeClaimFeeCoordinator: SmartCoordinator<Void> {
    let account: EthereumAccount
    let bundle: AsyncValue<WormholeBundle?>

    init(account: EthereumAccount, bundle: AsyncValue<WormholeBundle?>, presentation: SmartCoordinatorPresentation) {
        self.account = account
        self.bundle = bundle
        super.init(presentation: presentation)
    }

    override func build() -> UIViewController {
        let vm = WormholeClaimFeeViewModel(bundle: bundle)
        let view = WormholeClaimFeeView(viewModel: vm)
        let vc = UIBottomSheetHostingController(rootView: view)
        vc.view.layer.cornerRadius = 20

        vm.objectWillChange
            .sink { [weak vc] _ in
                DispatchQueue.main.async {
                    vc?.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)

        vm.closeAction.sink { [weak self] _ in
            self?.presentation.presentingViewController.dismiss(animated: true)
        }
        .store(in: &subscriptions)

        return vc
    }
}
