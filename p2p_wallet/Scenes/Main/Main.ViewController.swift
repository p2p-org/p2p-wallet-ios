//
//  MainViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Combine
import Foundation
import Resolver
import UIKit

extension Main {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: MainViewModelType
        private var subscriptions = Set<AnyCancellable>()

        // MARK: - Properties

        var authenticateWhenAppears: Bool!
        var viewModelViewDidLoad: Bool = false
        @Injected private var helpLauncher: HelpCenterLauncher
        @Injected private var solanaTracker: SolanaTracker

        // MARK: - Subviews

        private lazy var blurEffectView: UIView = LockView()
        private var localAuthVC: PincodeViewController?
        private lazy var tabBar = TabBarController()

        // MARK: - Initializer

        init(viewModel: MainViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            if authenticateWhenAppears {
                viewModel.authenticate(presentationStyle: .login())
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if !viewModelViewDidLoad {
                viewModel.viewDidLoad.send()
                viewModelViewDidLoad = true
            }
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()
            add(child: tabBar)
            view.addSubview(blurEffectView)
            blurEffectView.autoPinEdgesToSuperviewEdges()
        }

        override func bind() {
            super.bind()

            // delay authentication status
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [unowned self] in
                self.viewModel.authenticationStatusPublisher
                    .sink { [weak self] in self?.handleAuthenticationStatus($0) }
                    .store(in: &self.subscriptions)
            }

            viewModel.moveToHistory
                .sink { [unowned self] in
                    if available(.investSolendFeature) {
                        tabBar.changeItem(to: .history)
                    } else {
                        // old position of history tab controller
                        tabBar.changeItem(to: .invest)
                    }
                }
                .store(in: &subscriptions)
            // locking status
            viewModel.isLockedPublisher
                .sink { [weak self] isLocked in
                    isLocked ? self?.showLockView() : self?.hideLockView()
                }
                .store(in: &subscriptions)

            // blurEffectView
            viewModel.authenticationStatusPublisher
                .map { $0 == nil }
                .assign(to: \.isHidden, on: blurEffectView)
                .store(in: &subscriptions)
        }

        // MARK: - Locking

        private func showLockView() {
            UIApplication.shared.kWindow?.endEditing(true)
            let lockView = LockView()
            UIApplication.shared.windows.last?.addSubview(lockView)
            lockView.autoPinEdgesToSuperviewEdges()
            solanaTracker.stopTracking()
        }

        private func hideLockView() {
            for view in UIApplication.shared.windows.last?.subviews ?? [] where view is LockView {
                view.removeFromSuperview()
            }
        }

        // MARK: - Helpers

        private func handleAuthenticationStatus(_ authStyle: AuthenticationPresentationStyle?) {
            // dismiss
            guard let authStyle = authStyle else {
                localAuthVC?.dismiss(animated: true) { [weak self] in
                    self?.localAuthVC = nil
                }
                return
            }
            localAuthVC?.dismiss(animated: false, completion: nil)
            let pincodeViewModel = PincodeViewModel(
                state: .check,
                isBackAvailable: !authStyle.options.contains(.required),
                successNotification: ""
            )
            localAuthVC = PincodeViewController(viewModel: pincodeViewModel)
            if authStyle.options.contains(.fullscreen) {
                localAuthVC?.modalPresentationStyle = .fullScreen
            }

            var authSuccess = false
            pincodeViewModel.openMain.eraseToAnyPublisher()
                .sink { [weak self] _ in
                    authSuccess = true
                    self?.viewModel.authenticate(presentationStyle: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        authStyle.completion?(false)
                    }
                }
                .store(in: &subscriptions)
            pincodeViewModel.infoDidTap
                .sink(receiveValue: { [unowned self] in
                    helpLauncher.launch()
                })
                .store(in: &subscriptions)
            localAuthVC?.onClose = { [weak self] in
                self?.viewModel.authenticate(presentationStyle: nil)
                if authSuccess == false {
                    authStyle.onCancel?()
                }
            }
            presentLocalAuth()
        }

        private func presentLocalAuth() {
            let keyWindow = UIApplication.shared.windows.filter(\.isKeyWindow).first
            let topController = keyWindow?.rootViewController?.findLastPresentedViewController()
            if topController is UIAlertController {
                let presenting = topController?.presentingViewController
                topController?.dismiss(animated: false) { [weak presenting, weak localAuthVC] in
                    guard let localAuthVC = localAuthVC else { return }
                    presenting?.present(localAuthVC, animated: true)
                }
            } else {
                topController?.present(localAuthVC!, animated: true)
            }
        }
    }
}

private extension UIViewController {
    /// Recursively find last presentedViewController
    /// - Returns: the last presented view controller
    func findLastPresentedViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.findLastPresentedViewController()
        }
        return self
    }
}
