//
//  MainViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Combine
import Foundation
import UIKit

extension Main {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: MainViewModelType

        // MARK: - Properties

        var authenticateWhenAppears: Bool!
        var viewModelViewDidLoad: Bool = false
        private var subscriptions = [AnyCancellable]()

        // MARK: - Subviews

        private lazy var blurEffectView: UIView = LockView()
        private var localAuthVC: Authentication.ViewController?

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
                .sink { [weak self] in
                    self?.tabBar.changeItem(to: .history)
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
            let lockView = LockView()
            UIApplication.shared.windows.last?.addSubview(lockView)
            lockView.autoPinEdgesToSuperviewEdges()
        }

        private func hideLockView() {
            for view in UIApplication.shared.windows.last?.subviews ?? [] where view is LockView {
                view.removeFromSuperview()
            }
        }

        // MARK: - Helpers

        private func handleAuthenticationStatus(_ status: AuthenticationPresentationStyle?) {
            // dismiss
            guard let authStyle = status else {
                localAuthVC?.dismiss(animated: true) { [weak self] in
                    self?.localAuthVC = nil
                }
                return
            }

            // clean
            var extraAction: Authentication.ExtraAction = .none
            if authStyle.options.contains(.withResetPassword) { extraAction = .reset }
            if authStyle.options.contains(.withSignOut) { extraAction = .signOut }

            localAuthVC?.dismiss(animated: false, completion: nil)
            let vm = Authentication.ViewModel()
            localAuthVC = Authentication.ViewController(viewModel: vm, extraAction: extraAction)
            localAuthVC?.title = authStyle.title
            localAuthVC?.isIgnorable = !authStyle.options.contains(.required)
            localAuthVC?.useBiometry = !authStyle.options.contains(.disableBiometric)

            if authStyle.options.contains(.fullscreen) {
                localAuthVC?.modalPresentationStyle = .fullScreen
            }

            if authStyle.options.contains(.withLogo) {
                localAuthVC?.withLogo = true
            }

            // completion
            localAuthVC?.onSuccess = { [weak self] resetPassword in
                self?.viewModel.authenticate(presentationStyle: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authStyle.completion?(resetPassword)
                }
            }

            // cancelledCompletion
            if !authStyle.options.contains(.required) {
                // disable swipe down
                localAuthVC?.isModalInPresentation = true

                // handle cancelled by tapping <x>
                localAuthVC?.onCancel = { [weak self] in
                    self?.viewModel.authenticate(presentationStyle: nil)
                }
            }

            presentLocalAuth()
        }

        private func presentLocalAuth() {
            guard let localAuthVC = localAuthVC else {
                return assertionFailure("There is no local auth controller")
            }

            let keyWindow = UIApplication.shared.windows.filter(\.isKeyWindow).first
            let topController = keyWindow?.rootViewController?.findLastPresentedViewController()

            if topController is UIAlertController {
                let presenting = topController?.presentingViewController

                topController?.dismiss(animated: false) { [weak presenting, weak localAuthVC] in
                    guard let localAuthVC = localAuthVC else { return }

                    presenting?.present(localAuthVC, animated: true)
                }
            } else {
                topController?.present(localAuthVC, animated: true)
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
