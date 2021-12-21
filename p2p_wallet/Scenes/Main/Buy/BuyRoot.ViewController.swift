//
//  BuyRoot.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.12.21.
//

import Foundation
import UIKit
import Resolver
import SafariServices

extension BuyRoot {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        private var viewModel: BuyViewModelType
        let navigation: UINavigationController
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        init(crypto: Set<BuyProviders.Crypto>, walletRepository: WalletsRepository) {
            viewModel = ViewModel(walletRepository: walletRepository)
            navigation = UINavigationController(rootViewController: SolanaBuyToken.Scene(buyViewModel: viewModel))
            super.init()
        }
        
        // MARK: - Properties
        
        // MARK: - Methods
        override func setUp() {
            add(child: navigation)
            super.setUp()
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            do {
                switch scene {
                case .buyToken(let crypto, let amount):
                    let factory: BuyProviderFactory = Resolver.resolve()
                    let provider = try factory.create(walletRepository: viewModel.walletRepository, crypto: crypto, initialAmount: amount)
//                    let vc = try BuyToken.ViewController(provider: provider)
                    let vc = SFSafariViewController(url: URL(string: provider.getUrl())!)
                    vc.modalPresentationStyle = .automatic
                    present(vc, animated: true)
                case .back:
                    if navigation.children.count > 1 {
                        navigation.popViewController(animated: true)
                    } else {
                        back()
                    }
                default:
                    return
                }
            } catch let e {
                print(e)
            }
        }
    }
}
