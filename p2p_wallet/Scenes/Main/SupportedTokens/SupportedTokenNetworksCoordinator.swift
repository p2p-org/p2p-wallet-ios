import Foundation
import KeyAppUI
import SwiftUI

class SupportedTokenNetworksCoordinator: SmartCoordinator<SupportedTokenItemNetwork?> {
    let supportedToken: SupportedTokenItem

    init(supportedToken: SupportedTokenItem, viewController: UIViewController) {
        self.supportedToken = supportedToken
        super.init(presentation: SmartCoordinatorPresentPresentation(viewController))
    }

    override func build() -> UIViewController {
        let view = SupportedTokenNetworksView(item: supportedToken) { [weak self] network in
            
            self?.dismiss(network)
        }

        let vc = BottomSheetController(rootView: view)
        vc.view.backgroundColor = .init(resource: .smoke)

        return vc
    }
}
