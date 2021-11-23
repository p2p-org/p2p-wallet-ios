//
//  SendViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2021.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension SendToken {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Properties
        private let viewModel: SendTokenViewModelType
        private let scenesFactory: SendTokenScenesFactory
        
        // MARK: - Subviews
        private lazy var navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.titleLabel.text = L10n.send.uppercaseFirst
            navigationBar.backButton.onTap(self, action: #selector(back))
            return navigationBar
        }()
        private lazy var rootView = RootView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: SendTokenViewModelType, scenesFactory: SendTokenScenesFactory)
        {
            self.viewModel = viewModel
            self.scenesFactory = scenesFactory
            super.init()
            modalPresentationStyle = .custom
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            view.addSubview(navigationBar)
            navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
            
            view.addSubview(rootView)
            rootView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            rootView.autoPinEdge(.top, to: .bottom, of: navigationBar, withOffset: 8)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigatableSceneDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            switch scene {
            case .chooseWallet:
                let vc = scenesFactory.makeChooseWalletViewController(
                    customFilter: { $0.amount > 0},
                    showOtherWallets: false,
                    handler: viewModel
                )
                self.present(vc, animated: true, completion: nil)
            case .chooseAddress:
                break
            case .selectRecipient:
                let changeRecipient: (Recipient) -> Void = { [weak viewModel] recipient in
                    viewModel?.recipientChanged(recipient)
                }
                let vc = scenesFactory.makeSelectRecipientViewController(handler: changeRecipient)
                self.present(vc, animated: true)
            case .scanQrCode:
                let vc = QrCodeScannerVC()
                vc.callback = { [weak self] code in
                    if NSRegularExpression.publicKey.matches(code) {
                        self?.viewModel.enterWalletAddress(code)
                        return true
                    }
                    return false
                }
                vc.modalPresentationStyle = .custom
                self.present(vc, animated: true, completion: nil)
            case .chooseBTCNetwork(let selectedNetwork):
                let selectionVC = SingleSelectionViewController<SendRenBTCInfo.Network>(
                    title: L10n.destinationNetwork,
                    options: [.solana, .bitcoin],
                    selectedOption: selectedNetwork)
                { option, isSelected in
                    let view = WLDefaultOptionView()
                    view.label.text = option.rawValue.uppercaseFirst.localized()
                    view.setSelected(isSelected)
                    return view
                }
                selectionVC.completion = {[weak self] option in
                    self?.viewModel.changeRenBTCNetwork(to: option)
                }
                self.present(selectionVC, interactiveDismissalType: .standard)
            case .processTransaction(let request, let transactionType):
                let vc = scenesFactory.makeProcessTransactionViewController(transactionType: transactionType, request: request)
                self.present(vc, animated: true, completion: nil)
            case .feeInfo:
                let vc = FreeTransactionInfoVC()
                self.present(vc, animated: true, completion: nil)
            case .none:
                break
            }
        }
    }
}
