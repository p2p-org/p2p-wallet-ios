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
import WebKit

extension BuyRoot {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        private let viewModel: BuyViewModelType
        lazy var navigation = UINavigationController(
            rootViewController: SolanaBuyToken.Scene(
                viewModel: SolanaBuyToken.SceneModel(buyViewModel: viewModel, exchangeService: Resolver.resolve())
            )
        )
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        // MARK: - Properties
        
        // MARK: - Initializer
        init(viewModel: BuyViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
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
                    let factory: BuyProcessingFactory = Resolver.resolve()
                    let provider = try factory.create(
                        walletRepository: viewModel.walletsRepository,
                        crypto: crypto,
                        initialAmount: amount,
                        currency: .usd
                    )
                    // let vc = try BuyToken.ViewController(provider: provider)
                    let dataTypes = Set([WKWebsiteDataTypeCookies,
                                         WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage,
                                         WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
                    WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) { [weak self] in
                        let vc = SFSafariViewController(url: URL(string: provider.getUrl())!)
                        vc.modalPresentationStyle = .automatic
                        self?.present(vc, animated: true)
                    }
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
                debugPrint(e)
            }
        }
    }
}
