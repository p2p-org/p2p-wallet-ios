// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Resolver
import SwiftUI

class PincodeChangeCoordinator: Coordinator<Bool> {
    private let navVC: UINavigationController
    private let transition = PanelTransition()

    @Injected private var pincodeStorage: PincodeStorageType
    let result = PassthroughSubject<Bool, Never>()

    init(navVC: UINavigationController) {
        self.navVC = navVC
        super.init()

        transition.dimmClicked
            .sink { navVC.dismiss(animated: true) }
            .store(in: &subscriptions)
    }

    override func start() -> AnyPublisher<Bool, Never> {
        var pincodeChangeStartView = PincodeChangeStartView()
        pincodeChangeStartView.startChanging = { [openVerifyPincode] in openVerifyPincode() }

        let pincodeChangeStartVC = UIHostingController(rootView: pincodeChangeStartView)
        pincodeChangeStartVC.title = L10n.pinCode
        pincodeChangeStartVC.hidesBottomBarWhenPushed = true

        pincodeChangeStartVC.onClose = { [result] in
            result.send(false)
            result.send(completion: .finished)
        }

        navVC.pushViewController(pincodeChangeStartVC, animated: true)

        return result.eraseToAnyPublisher()
    }

    func openVerifyPincode() {
        var view = PincodeVerifyView()
        view.onSuccess = { [openCreatePincode] in openCreatePincode() }
        view.forgetPinCode = { [weak self] in
            guard let self = self else { return }
            var view = ForgetPinView()
            view.close = { self.navVC.dismiss(animated: true) }

            self.transition.containerHeight = view.viewHeight
            let viewController = UIHostingController(rootView: view)
            viewController.view.layer.cornerRadius = 20
            viewController.transitioningDelegate = self.transition
            viewController.modalPresentationStyle = .custom
            self.navVC.present(viewController, animated: true)
        }

        let vc = UIHostingController(rootView: view)
        vc.title = L10n.changePIN
        navVC.pushViewController(vc, animated: true)
    }

    func openCreatePincode() {
        let viewModel = PincodeViewModel(state: .create, isBackAvailable: false, successNotification: "")
        let viewController = PincodeViewController(viewModel: viewModel)
        viewController.title = L10n.changePIN

        viewModel.title = L10n.createYourPINCode
        viewModel.confirmPin
            .sinkAsync { [openConfirmPincode] pincode in
                openConfirmPincode(pincode)
            }
            .store(in: &subscriptions)

        var vcs = Array(navVC.viewControllers.dropLast(1))
        vcs.append(viewController)

        navVC.setViewControllers(vcs, animated: true)
    }

    func openConfirmPincode(pincode: String) {
        let viewModel = PincodeViewModel(
            state: .confirm(pin: pincode, askBiometric: false),
            isBackAvailable: false,
            successNotification: "🤗 " + L10n.yourPINWasChanged
        )
        let viewController = PincodeViewController(viewModel: viewModel)
        viewController.title = L10n.changePIN

        viewModel.title = L10n.confirmYourPINCode
        viewModel.openMain
            .sinkAsync { [result, pincodeStorage] _ in
                pincodeStorage.save(pincode)
                result.send(true)
                result.send(completion: .finished)
            }
            .store(in: &subscriptions)

        navVC.pushViewController(viewController, animated: true)
    }
}
