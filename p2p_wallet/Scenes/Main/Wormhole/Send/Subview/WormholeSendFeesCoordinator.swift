import Foundation
import Send
import TokenService
import UIKit

class WormholeSendFeesCoordinator: SmartCoordinator<Void> {
    let stateMachine: WormholeSendInputStateMachine

    init(stateMachine: WormholeSendInputStateMachine, presentedVC: UIViewController) {
        self.stateMachine = stateMachine
        super.init(presentation: SmartCoordinatorPresentPresentation(presentedVC))
    }

    override func build() -> UIViewController {
        let vm = WormholeSendFeesViewModel(stateMachine: stateMachine)
        let view = WormholeSendFeesView(viewModel: vm)
        let vc = UIBottomSheetHostingController(rootView: view)
        vc.view.layer.cornerRadius = 20

        vm.objectWillChange
            .delay(for: 0.01, scheduler: RunLoop.main)
            .sink { [weak vc] _ in
                DispatchQueue.main.async {
                    vc?.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)

        vm.close.sink { [weak vc] in
            vc?.dismiss(animated: true)
        }.store(in: &subscriptions)

        return vc
    }
}
