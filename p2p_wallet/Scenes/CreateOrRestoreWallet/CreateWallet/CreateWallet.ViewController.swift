//
//  CreateWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import Resolver
import UIKit

extension CreateWallet {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies

        private let viewModel: CreateWalletViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType

        // MARK: - Properties

        var childNavigationController: UINavigationController!

        // MARK: - Initializer

        init(viewModel: CreateWalletViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func viewDidLoad() {
            super.viewDidLoad()
            viewModel.kickOff()
            analyticsManager.log(event: .createWalletOpen)
        }

        override func setUp() {
            super.setUp()
            childNavigationController = .init()
            childNavigationController.setNavigationBarHidden(true, animated: false)
            view.addSubview(childNavigationController.view)
        }

        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: CreateWallet.NavigatableScene?) {
            guard let scene = scene else {
                return
            }
            switch scene {
            case .explanation:
                let vc = ExplanationVC(viewModel: viewModel)
                childNavigationController.pushViewController(vc, animated: true)
            case .createPhrases:
                let vm = CreateSecurityKeys.ViewModel(createWalletViewModel: viewModel)
                let vc = CreateSecurityKeys.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case let .reserveName(owner):
                let viewModel = ReserveName.ViewModel(
                    kind: .reserveCreateWalletPart,
                    owner: owner,
                    reserveNameHandler: viewModel,
                    checkBeforeReserving: false
                )
                let viewController = ReserveName.ViewController(viewModel: viewModel)
                childNavigationController.pushViewController(viewController, animated: true)
            case let .verifyPhrase(phrase):
                let vm = VerifySecurityKeys.ViewModel(keyPhrase: phrase, createWalletViewModel: viewModel)
                let vc = VerifySecurityKeys.ViewController(viewModel: vm)
                childNavigationController.pushViewController(vc, animated: true)
            case .dismiss:
                navigationController?.popViewController(animated: true)
            case .back:
                if childNavigationController.viewControllers.count > 1 {
                    childNavigationController.popViewController(animated: true)
                } else {
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
