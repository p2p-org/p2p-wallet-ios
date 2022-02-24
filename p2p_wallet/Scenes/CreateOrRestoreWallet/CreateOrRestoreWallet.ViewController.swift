//
//  CreateOrRestoreWallet.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import Foundation
import UIKit

extension CreateOrRestoreWallet {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: CreateOrRestoreWalletViewModelType
        @Injected private var analyticsManager: AnalyticsManagerType
        private lazy var introPlayer: IntroPlayerType = Resolver.resolve(args: IntroPlayerTheme.w)
        
        // MARK: - Subviews
        private lazy var introPlayerLayer = introPlayer.createLayer()
        private lazy var videoPlayerView: UIView = {
            let view = UIView(forAutoLayout: ())
            view.layer.addSublayer(introPlayerLayer)
            return view
        }()
        
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
            analyticsManager.log(event: .firstInOpen)
            
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
            
            containerView.addSubview(videoPlayerView)
            if view.bounds.width < view.bounds.height {
                videoPlayerView.autoPinEdge(toSuperviewEdge: .left)
                videoPlayerView.autoPinEdge(toSuperviewEdge: .right)
            } else {
                videoPlayerView.autoPinEdge(toSuperviewEdge: .top)
                videoPlayerView.autoPinEdge(toSuperviewEdge: .bottom)
            }
            videoPlayerView.autoAdjustWidthHeightRatio(1080/1130)
            videoPlayerView.autoAlignAxis(toSuperviewAxis: .horizontal)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            introPlayerLayer.frame = videoPlayerView.bounds
            introPlayer.resume()
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .createWallet:
                let vm = CreateWallet.ViewModel()
                let vc = CreateWallet.ViewController(viewModel: vm)
                show(vc, sender: nil)
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
            viewModel.navigateToCreateWalletScene()
        }

        @objc private func navigateToRestoreWalletScene() {
            viewModel.navigateToRestoreWalletScene()
        }
    }
}
