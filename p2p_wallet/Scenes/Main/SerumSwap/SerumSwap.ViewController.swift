//
//  SerumSwap.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import UIKit


//@objc protocol SerumSwapViewControllerDelegate {
//
//}

extension SerumSwap {
    class ViewController: WLIndicatorModalVC, CustomPresentableViewController {
        // MARK: - Properties
        var transitionManager: UIViewControllerTransitioningDelegate?
        private let viewModel: SerumSwapViewModelType
        private let scenesFactory: SerumSwapScenesFactory
        
        // MARK: - Subviews
        private lazy var headerView = UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
            UILabel(text: L10n.swap, textSize: 17, weight: .semibold),
            UIImageView(width: 36, height: 36, image: .slippageSettings, tintColor: .iconSecondary)
                .onTap(self, action: #selector(showSettings))
        ])
            .padding(.init(all: 20))
        private lazy var rootView = RootView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(
            viewModel: SerumSwapViewModelType,
            scenesFactory: SerumSwapScenesFactory)
        {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                headerView
                UIView.defaultSeparator()
                rootView
            }
            
            containerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
            
            viewModel.isLoadingDriver
                .drive(onNext: {[weak self] isLoading in
                    if isLoading {
                        self?.showIndetermineHud(nil)
                    } else {
                        self?.hideHud()
                    }
                })
                .disposed(by: disposeBag)
            
//            viewModel.output.pool.map {$0 == nil}
//                .distinctUntilChanged()
//                .drive(onNext: {[weak self] _ in
//                    self?.updatePresentationLayout(animated: true)
//                })
//                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func showSettings() {
            navigate(to: .settings)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
//            switch scene {
//            case .chooseSourceWallet:
//                let vc = scenesFactory.makeChooseWalletViewController(
//                    customFilter: {$0.amount > 0},
//                    showOtherWallets: false,
//                    handler: viewModel
//                )
//                present(vc, animated: true, completion: nil)
//            case .chooseDestinationWallet(let validMints, let sourceWalletPubkey):
//                let vc = scenesFactory.makeChooseWalletViewController(
//                    customFilter: {
//                        $0.pubkey != sourceWalletPubkey &&
//                            validMints.contains($0.mintAddress)
//                    },
//                    showOtherWallets: true,
//                    handler: viewModel
//                )
//                present(vc, animated: true, completion: nil)
//            case .settings:
//                let vc = SettingsViewController(viewModel: viewModel)
//                present(SettingsNavigationController(rootViewController: vc), interactiveDismissalType: .standard)
//            case .chooseSlippage:
//                let vc = SlippageSettingsViewController()
//                vc.completion = {[weak self] slippage in
//                    Defaults.slippage = slippage / 100
//                    self?.viewModel.input.slippage.accept(slippage / 100)
//                }
//                present(SettingsNavigationController(rootViewController: vc), interactiveDismissalType: .standard)
//            case .swapFees:
//                let vc = SwapFeesViewController(viewModel: viewModel)
//                present(SettingsNavigationController(rootViewController: vc), interactiveDismissalType: .standard)
//            case .processTransaction(let request, let transactionType):
//                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
//                self.present(vc, animated: true, completion: nil)
//            default:
//                break
//            }
        }
        
        // MARK: - Transitions
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            super.calculateFittingHeightForPresentedView(targetWidth: targetWidth)
                + headerView.fittingHeight(targetWidth: targetWidth)
                + 1 // separator
                + rootView.fittingHeight(targetWidth: targetWidth)
        }
        
        override var scrollViewAvoidingTabBar: UIScrollView? {
            rootView.scrollView
        }
    }
}
