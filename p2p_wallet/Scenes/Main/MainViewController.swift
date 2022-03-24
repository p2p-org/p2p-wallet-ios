//
//  MainViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Action
import Foundation
import UIKit

class MainViewController: BaseVC {
    // MARK: - Dependencies

    private let viewModel: MainViewModelType

    // MARK: - Properties

    var authenticateWhenAppears: Bool!

    // MARK: - Subviews

    private lazy var blurEffectView: UIView = LockView()
    private var localAuthVC: Authentication.ViewController?

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

    // MARK: - Methods

    override func setUp() {
        super.setUp()
        add(child: TabBarVC())
        view.addSubview(blurEffectView)
        blurEffectView.autoPinEdgesToSuperviewEdges()
    }

    override func bind() {
        super.bind()
        // authentication status
        viewModel.authenticationStatusDriver
            .drive(onNext: { [weak self] in self?.handleAuthenticationStatus($0) })
            .disposed(by: disposeBag)

        // blurEffectView
        viewModel.authenticationStatusDriver
            .map { $0 == nil }
            .drive(blurEffectView.rx.isHidden)
            .disposed(by: disposeBag)
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
