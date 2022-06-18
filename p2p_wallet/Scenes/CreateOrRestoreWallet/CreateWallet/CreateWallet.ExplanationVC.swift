//
// Created by Giang Long Tran on 01.11.21.
//

import Foundation
import UIKit

extension CreateWallet {
    class ExplanationVC: BaseVC {
        // MARK: - Subviews

        private let createWalletButton: WLStepButton = WLStepButton.main(
            image: .key,
            imageSize: CGSize(width: 16, height: 15),
            text: L10n.showYourSecurityKey
        )

        // MARK: - Dependencies

        private let viewModel: CreateWalletViewModelType

        // MARK: - Initializer

        init(viewModel: CreateWalletViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()

            // pattern background view
            let patternView = UIImageView(image: .introPatternBg, tintColor: .textSecondary.withAlphaComponent(0.05))
            view.addSubview(patternView)
            patternView.autoPinEdgesToSuperviewEdges()

            // navigation bar
            navigationItem.title = L10n.createANewWallet

            // content
            let illustration = UIView.ilustrationView(
                image: .explanationPicture,
                title: L10n.secureYourWallet,
                description: L10n
                    .TheFollowingWordsAreTheSecurityKeyThatYouMustKeepInASafePlaceWrittenInTheCorrectSequence
                    .IfLostNoOneCanRestoreIt.keepItPrivateEvenFromUs
            )

            view.addSubview(illustration)
            illustration.autoPinEdge(toSuperviewSafeArea: .top)
            illustration.autoPinEdge(toSuperviewSafeArea: .left, withInset: 18)
            illustration.autoPinEdge(toSuperviewSafeArea: .right, withInset: 18)

            // bottom button
            view.addSubview(createWalletButton)
            createWalletButton.autoPinEdgesToSuperviewSafeArea(with: .init(x: 18, y: 20), excludingEdge: .top)
            createWalletButton.autoPinEdge(.top, to: .bottom, of: illustration, withOffset: 10)
            createWalletButton.onTap(self, action: #selector(navigateToCreateWalletScene))
        }

        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        // MARK: - Navigation

        private func navigate(to scene: CreateWallet.NavigatableScene?) {
            guard let scene = scene else { return }

            switch scene {
            case .createPhrases:
                let vm = CreateSecurityKeys.ViewModel(createWalletViewModel: viewModel)
                let vc = CreateSecurityKeys.ViewController(viewModel: vm)
                navigationController?.pushViewController(vc, animated: true)
            case let .reserveName(owner):
                let viewModel = ReserveName.ViewModel(
                    kind: .reserveCreateWalletPart,
                    owner: owner,
                    reserveNameHandler: viewModel,
                    checkBeforeReserving: false
                )
                let viewController = ReserveName.ViewController(viewModel: viewModel)
                navigationController?.pushViewController(viewController, animated: true)
            case let .verifyPhrase(phrase):
                let vm = VerifySecurityKeys.ViewModel(keyPhrase: phrase, createWalletViewModel: viewModel)
                let vc = VerifySecurityKeys.ViewController(viewModel: vm)
                navigationController?.pushViewController(vc, animated: true)
            case .dismiss:
                navigationController?.popViewController(animated: true)
            default:
                break
            }
        }

        // MARK: - Navigation

        @objc private func navigateToCreateWalletScene() {
            viewModel.navigateToCreatePhrases()
        }

        @objc private func _back() {
            viewModel.back()
        }
    }
}
