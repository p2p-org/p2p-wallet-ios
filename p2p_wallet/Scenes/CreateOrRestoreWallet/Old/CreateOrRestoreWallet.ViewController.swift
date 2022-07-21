//
//  CreateOrRestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import AnalyticsManager
import Combine
import Foundation
import Onboarding
import Resolver
import UIKit

extension CreateOrRestoreWallet {
    class ViewController: BaseVC {
        private var subscriptions = [AnyCancellable]()

        // MARK: - Dependencies

        private let viewModel: CreateOrRestoreWalletViewModelType
        @Injected private var analyticsManager: AnalyticsManager

        private var currentChildCoordinator: CreateWalletCoordinator?

        // MARK: - Subviews

        private var videoPlayerView: IntroPlayerView!

        private lazy var createWalletButton = WLStepButton.main(
            image: .walletButtonSmall,
            text: L10n.createNewWallet.uppercaseFirst
        )
            .onTap(self, action: #selector(navigateToCreateWalletScene))
        private lazy var restoreWalletButton = WLStepButton.sub(
            text: L10n.iAlreadyHaveAWallet.uppercaseFirst
        )
            .onTap(self, action: #selector(navigateToRestoreWalletScene))

        // MARK: - Initializer

        init(viewModel: CreateOrRestoreWalletViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            super.setUp()
            analyticsManager.log(event: .splashViewed)

            // pattern background view
            let patternView = UIView.introPatternView()
            view.addSubview(patternView)
            patternView.autoPinEdgesToSuperviewEdges()

            // pagevc's container view
            let containerView = UIView(forAutoLayout: ())
            view.addSubview(containerView)
            containerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            // button stack view
            let buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
                createWalletButton
                    .withContentHuggingPriority(.required, for: .horizontal)
                restoreWalletButton
                    .withContentHuggingPriority(.required, for: .horizontal)
            }
            .withContentHuggingPriority(.required, for: .horizontal)

            view.addSubview(buttonStackView)
            buttonStackView.autoPinEdgesToSuperviewSafeArea(with: .init(x: 18, y: 20), excludingEdge: .top)
            buttonStackView.autoPinEdge(.top, to: .bottom, of: containerView)

            // set up container view
//            add(child: WelcomeVC(), to: containerView)

            videoPlayerView = IntroPlayerView(userInterfaceStyle: traitCollection.userInterfaceStyle)
            videoPlayerView.skip = true
            videoPlayerView.autoAdjustWidthHeightRatio(1080 / 1130)
            videoPlayerView.autoSetDimension(.height, toSize: 349.adaptiveHeight)

            let ilustrationView: UIView = .ilustrationView(
                title: L10n.p2PWallet,
                description: L10n.theFutureOfNonCustodialBankingTheEasyWayToBuySellAndHoldCryptos,
                replacingImageWithCustomView: videoPlayerView
            )

            containerView.addSubview(ilustrationView)
            ilustrationView.autoPinEdgesToSuperviewSafeArea(
                with: .init(all: 20, excludingEdge: .bottom),
                excludingEdge: .bottom
            )
            ilustrationView.autoPinEdge(.bottom, to: .top, of: buttonStackView, withOffset: -55)
        }

        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            videoPlayerView.resume()
        }

        // MARK: - Navigation

        @MainActor private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .createWallet:
                // let vm = CreateWallet.ViewModel()
                // let vc = CreateWallet.ExplanationVC(viewModel: vm)
                // show(vc, sender: nil)

                guard currentChildCoordinator == nil else { return }

                Task {
                    let webView = GlobalWebView.requestWebView()
                    do {
                        let tKeyFacade = TKeyJSFacade(wkWebView: webView)
                        try await tKeyFacade.initialize()

                        let vm = CreateWalletViewModel(tKeyFacade: tKeyFacade)
                        currentChildCoordinator = CreateWalletCoordinator(viewModel: vm)
                        currentChildCoordinator?.start()
                            .sink(receiveCompletion: { [weak self, weak currentChildCoordinator] completion in
                                switch completion {
                                case .finished:
                                    guard let vc = currentChildCoordinator?.navigationController else {
                                        return
                                    }
                                    self?.show(vc, sender: nil)
                                case .failure:
                                    break
                                }

                            }, receiveValue: { _ in })
                            .store(in: &subscriptions)
                    } catch {
                        webView.removeFromSuperview()
                    }
                }
            case .restoreWallet:
                let vm = RestoreWallet.ViewModel()
                let vc = RestoreWallet.ViewController(viewModel: vm)
                show(vc, sender: nil)
            }
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .portrait
        }

        override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
            .portrait
        }

        @objc private func navigateToCreateWalletScene() {
            videoPlayerView.completion = { [weak self] in
                self?.viewModel.navigateToCreateWalletScene()
            }
            videoPlayerView.playNext()
        }

        @objc private func navigateToRestoreWalletScene() {
            videoPlayerView.completion = { [weak self] in
                self?.viewModel.navigateToRestoreWalletScene()
            }
            videoPlayerView.playNext()
        }
    }
}
