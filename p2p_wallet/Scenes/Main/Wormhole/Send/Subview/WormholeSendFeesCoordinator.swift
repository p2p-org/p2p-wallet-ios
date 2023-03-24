//
//  WormholeSendFeesCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import Send

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

        vm.objectWillChange
            .sink { [weak vc] _ in
                DispatchQueue.main.async {
                    vc?.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)

        return vc
    }
}
