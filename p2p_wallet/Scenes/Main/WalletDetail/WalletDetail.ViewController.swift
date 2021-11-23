//
//  WalletDetail.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import BEPureLayout
import RxSwift
import UIKit

protocol WalletDetailScenesFactory {
    func makeBuyTokenViewController(token: BuyToken.CryptoCurrency) throws -> UIViewController
    func makeReceiveTokenViewController(tokenWalletPubkey: String?) -> ReceiveToken.ViewController?
    func makeSendTokenViewController(walletPubkey: String?, destinationAddress: String?) -> SendToken.ViewController
    func makeSwapTokenViewController(provider: SwapProvider, fromWallet wallet: Wallet?) -> CustomPresentableViewController
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
    func makeTransactionInfoViewController(transaction: SolanaSDK.ParsedTransaction) -> TransactionInfoViewController
}

extension WalletDetail {
    class ViewController: BEPagesVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: WalletDetailViewModelType
        private let scenesFactory: WalletDetailScenesFactory
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.backButton.onTap(self, action: #selector(back))
            let editButton = UIImageView(width: 24, height: 24, image: .navigationBarEdit)
                .onTap(self, action: #selector(showWalletSettings))
            navigationBar.rightItems.addArrangedSubview(editButton)
            return navigationBar
        }()
        
        private lazy var segmentedControl: UISegmentedControl = {
            let control = UISegmentedControl(items: [L10n.info, L10n.history])
            control.addTarget(self, action: #selector(segmentedValueChanged(_:)), for: .valueChanged)
            control.autoSetDimension(.width, toSize: 339, relation: .greaterThanOrEqual)
            return control
        }()
        
        // MARK: - Subscene
        private lazy var infoVC: InfoViewController = {
            let vc = InfoViewController(viewModel: viewModel)
            return vc
        }()
        
        private lazy var historyVC: HistoryViewController = {
            let vc = HistoryViewController(viewModel: viewModel)
            return vc
        }()
        
        // MARK: - Initializer
        init(
            viewModel: WalletDetailViewModelType,
            scenesFactory: WalletDetailScenesFactory
        ) {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            view.addSubview(segmentedControl)
            segmentedControl.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
            segmentedControl.autoAlignAxis(toSuperviewAxis: .vertical)
            
            super.setUp()
            view.backgroundColor = .background
            
            viewControllers = [infoVC, historyVC]
            
            // action
            currentPage = -1
            moveToPage(0)
            
            segmentedControl.selectedSegmentIndex = 0
        }
        
        override func setUpContainerView() {
            view.addSubview(containerView)
            containerView.autoPinEdge(.top, to: .bottom, of: segmentedControl, withOffset: 18)
            containerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        }
        
        override func setUpPageControl() {
            // do nothing
        }
        
        override func bind() {
            super.bind()
            viewModel.walletDriver.map {$0?.name}
                .drive(navigationBar.titleLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        override func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            super.pageViewController(pageViewController, didFinishAnimating: finished, previousViewControllers: previousViewControllers, transitionCompleted: completed)
            if let vc = pageVC.viewControllers?.first,
               let index = viewControllers.firstIndex(of: vc),
               segmentedControl.selectedSegmentIndex != index
            {
                segmentedControl.selectedSegmentIndex = index
            }
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .buy(let tokens):
                do {
                    let vc = try scenesFactory.makeBuyTokenViewController(token: tokens)
                    present(vc, animated: true, completion: nil)
                } catch {
                    showAlert(title: L10n.error, message: error.readableDescription)
                }
            case .settings(let pubkey):
                let vc = scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            case .send(let wallet):
                let vc = scenesFactory.makeSendTokenViewController(walletPubkey: wallet.pubkey, destinationAddress: nil)
                show(vc, sender: nil)
            case .receive(let pubkey):
                if let vc = scenesFactory.makeReceiveTokenViewController(tokenWalletPubkey: pubkey)
                {
                    present(vc, interactiveDismissalType: .standard, completion: nil)
                }
            case .swap(let wallet):
                let vc = scenesFactory.makeSwapTokenViewController(provider: .orca, fromWallet: wallet)
                present(vc, interactiveDismissalType: .standard, completion: nil)
            case .transactionInfo(let transaction):
                let vc = scenesFactory.makeTransactionInfoViewController(transaction: transaction)
                present(vc, interactiveDismissalType: .standard, completion: nil)
            default:
                break
            }
        }
        
        // MARK: - Actions
        @objc func segmentedValueChanged(_ sender: UISegmentedControl!) {
            moveToPage(sender.selectedSegmentIndex)
        }
        
        @objc func showWalletSettings() {
            viewModel.showWalletSettings()
        }
    }
}

extension WalletDetail.ViewController: TokenSettingsViewControllerDelegate {
    func tokenSettingsViewControllerDidCloseToken(_ vc: TokenSettingsViewController) {
        dismiss(animated: true, completion: nil)
    }
}
