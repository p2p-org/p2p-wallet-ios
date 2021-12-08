//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import Foundation
import UIKit

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class ViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        
        // MARK: - Properties
        
        // MARK: - Inititalizer
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func loadView() {
            view = RootView(viewModel: viewModel)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .scanQrCode:
                let vc = QrCodeScannerVC()
                vc.callback = { [weak self] code in
                    if NSRegularExpression.publicKey.matches(code) {
                        self?.viewModel.search(code)
                        return true
                    }
                    return false
                }
                vc.modalPresentationStyle = .custom
                present(vc, animated: true, completion: nil)
            }
        }
    }
}
