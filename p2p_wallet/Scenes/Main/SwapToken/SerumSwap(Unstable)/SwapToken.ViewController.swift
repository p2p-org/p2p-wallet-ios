//
//  SwapToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import UIKit
import RxCocoa

extension SerumSwapV1 {
    class ViewController: WLIndicatorModalVC, CustomPresentableViewController {
        // MARK: - Properties
        var transitionManager: UIViewControllerTransitioningDelegate?
        private let viewModel: SwapTokenViewModelType
        private let scenesFactory: SwapTokenScenesFactory
        
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
            viewModel: SwapTokenViewModelType,
            scenesFactory: SwapTokenScenesFactory)
        {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
            modalPresentationStyle = .custom
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
            
            viewModel.initialStateDriver
                .map {$0 == .loading}
                .drive(onNext: {[weak self] isLoading in
                    if isLoading {
                        self?.showIndetermineHud(nil)
                    } else {
                        self?.hideHud()
                    }
                })
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.slippageDriver,
                viewModel.errorDriver,
                viewModel.feesDriver,
                viewModel.exchangeRateDriver
            )
                .drive(onNext: {[weak self] _ in
                    self?.updatePresentationLayout(animated: true)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func showSettings() {
            navigate(to: .settings)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .chooseSourceWallet:
                let vc = scenesFactory.makeChooseWalletViewController(
                    title: L10n.selectTheFirstToken,
                    customFilter: {$0.amount > 0},
                    showOtherWallets: false,
                    selectedWallet: nil,
                    handler: viewModel
                )
                present(vc, animated: true, completion: nil)
            case .chooseDestinationWallet:
                var filter: ((Wallet) -> Bool)?
                if let sourceWallet = viewModel.getSourceWallet() {
                    filter = {
                        $0.pubkey != sourceWallet.pubkey
                    }
                }
                let vc = scenesFactory.makeChooseWalletViewController(
                    title: L10n.selectTheSecondToken,
                    customFilter: filter,
                    showOtherWallets: true,
                    selectedWallet: nil,
                    handler: viewModel
                )
                present(vc, animated: true, completion: nil)
            case .settings:
                let vc = SettingsViewController(viewModel: viewModel)
                let nc = SettingsNavigationController(rootViewController: vc)
                nc.modalPresentationStyle = .custom
                present(nc, interactiveDismissalType: .standard)
            case .chooseSlippage:
                let vc = SlippageSettingsViewController()
                vc.completion = {[weak self] slippage in
                    Defaults.slippage = slippage / 100
                    self?.viewModel.changeSlippage(to: Defaults.slippage)
                }
                present(SettingsNavigationController(rootViewController: vc), interactiveDismissalType: .standard)
            case .swapFees:
                let vc = SwapFeesViewController(viewModel: viewModel)
                present(SettingsNavigationController(rootViewController: vc), interactiveDismissalType: .standard)
            case .processTransaction(let request, let transactionType):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                self.present(vc, animated: true, completion: nil)
            default:
                break
            }
        }
        
        // MARK: - Transitions
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            super.calculateFittingHeightForPresentedView(targetWidth: targetWidth)
                + headerView.fittingHeight(targetWidth: targetWidth)
                + 1 // separator
                + rootView.fittingHeight(targetWidth: targetWidth)
        }
    }
}
