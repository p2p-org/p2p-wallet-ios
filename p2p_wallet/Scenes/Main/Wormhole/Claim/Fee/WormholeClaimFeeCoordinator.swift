import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import KeychainSwift
import UIKit
import Wormhole

class WormholeClaimFeeCoordinator: SmartCoordinator<Void> {
    let bundle: AsyncValue<WormholeBundle?>

    init(account _: EthereumAccount, bundle: AsyncValue<WormholeBundle?>, presentation: SmartCoordinatorPresentation) {
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
