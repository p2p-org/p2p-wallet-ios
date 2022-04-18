//
//  Root.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxAppState
import UIKit

extension Root {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: RootViewModelType

        // MARK: - Initializer

        init(viewModel: RootViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func loadView() {
            view = LockView()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()
            viewModel.reload()
        }

        override func bind() {
            super.bind()
            // remove all childs
            viewModel.resetSignal
                .emit(onNext: { [weak self] in self?.removeAllChilds() })
                .disposed(by: disposeBag)

            // navigation scene
            viewModel.navigationSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)

            // loadingView
            viewModel.isLoadingDriver
                .drive(onNext: { [weak self] isLoading in
                    isLoading ? self?.showIndetermineHud() : self?.hideHud()
                })
                .disposed(by: disposeBag)

            UIApplication.shared.rx
                .applicationWillResignActive
                .subscribe(onNext: { [weak self] _ in
                    self?.showLockView()
                })
                .disposed(by: disposeBag)

            UIApplication.shared.rx
                .applicationDidBecomeActive
                .subscribe(onNext: { [weak self] _ in
                    self?.hideLockView()
                })
                .disposed(by: disposeBag)
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

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .createOrRestoreWallet:
                let vm = CreateOrRestoreWallet.ViewModel()
                let vc = CreateOrRestoreWallet.ViewController(viewModel: vm)
                let nc = UINavigationController(rootViewController: vc)
                transition(to: nc)
            case .onboarding:
                let vm = Onboarding.ViewModel()
                let vc = Onboarding.ViewController(viewModel: vm)
                transition(to: vc)
            case let .onboardingDone(isRestoration, name):
                let vc = WelcomeViewController(isReturned: isRestoration, name: name, viewModel: viewModel)
                transition(to: vc)
            case let .main(showAuthenticationWhenAppears):
                // MainViewController
                let vm = MainViewModel()
                let vc = MainViewController(viewModel: vm)
                vc.authenticateWhenAppears = showAuthenticationWhenAppears
                transition(to: vc)
            default:
                break
            }
        }
    }
}
