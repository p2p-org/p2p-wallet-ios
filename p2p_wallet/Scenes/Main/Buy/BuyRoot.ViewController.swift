//
//  BuyRoot.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.12.21.
//

import Combine
import Foundation
import Resolver
import SafariServices
import UIKit
import WebKit

extension BuyRoot {
    class ViewController: BaseVC {
        // MARK: - Dependencies

        private let viewModel: BuyViewModelType
        private let navigation: UINavigationController

        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        private var subscriptions = [AnyCancellable]()

        // MARK: - Initializer

        init(crypto: Buy.CryptoCurrency = .sol, viewModel: BuyViewModelType) {
            self.viewModel = viewModel
            navigation = UINavigationController(
                rootViewController: BuyPreparing.Scene(
                    viewModel: BuyPreparing.SceneModel(
                        crypto: crypto,
                        exchangeService: Resolver.resolve()
                    )
                )
            )

            super.init()
        }

        // MARK: - Methods

        override func setUp() {
            add(child: navigation)
            super.setUp()
        }

        override func bind() {
            super.bind()
            viewModel.navigationPublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)
        }

        // MARK: - Navigation

        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            do {
                switch scene {
                case let .buyToken(crypto, amount):
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
                    WKWebsiteDataStore.default()
                        .removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) { [weak self] in
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
