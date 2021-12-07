//
//  BuyToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/09/2021.
//

import Foundation
import UIKit

extension BuyToken {
    class ViewController: WLIndicatorModalVC {
        // MARK: - Properties
        private let widgetVC: BuyTokenWidgetViewController
        private lazy var headerView = UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .white)
                    .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
            UILabel(text: L10n.buy, textSize: 17, weight: .semibold)
        ])
                .padding(.init(all: 20))

        // MARK: - Methods
        init(token: CryptoCurrency, repository: WalletsRepository) throws {
            let provider = try getEnvironmentAndParams(type: .default, token: token, repository: repository)
            widgetVC = .init(provider: provider, loadingView: WLSpinnerView(size: 65, endColor: .h5887ff))
            super.init()
        }

        override func setUp() {
            super.setUp()

            let rootView = UIView(forAutoLayout: ())
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                headerView
                UIView.defaultSeparator()
                rootView
            }

            containerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()

            add(child: widgetVC, to: rootView)
        }
    }
}

enum BuyProviderType: Equatable {
    case transak
    case moonpay
    
    static var `default`: Self {
        .moonpay
    }
    
    func isSupported(symbol: String) -> Bool {
        switch self {
        case .moonpay:
            return symbol == "USDT"
        case .transak:
            return symbol == "SOL" || symbol == "USDT"
        }
    }
}

private func getEnvironmentAndParams(type: BuyProviderType, token: BuyToken.CryptoCurrency, repository: WalletsRepository) throws -> BuyProvider {
    let wallets = repository.getWallets()
    let defaultCryptoCurrency: String? = {
        switch token {
        case .sol, .all:
            // TODO: this line should return SOL.
            // Moonpay doesn't support SOL currency.
            return type == .moonpay ? nil : "SOL"
        case .usdt:
            return "USDT"
        default:
            return nil
        }
    }()
    let walletAddress: String? = try {
        switch token {
        case .sol:
            guard let address = wallets.first(where: { $0.isNativeSOL })?.pubkey else {
                throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("SOL"))
            }
            return address
        case .usdt:
            guard let address = wallets.first(where: { $0.token.symbol == "USDT" })?.pubkey else {
                throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("USDT"))
            }
            return address
        case .all:
            return nil
        default:
            throw SolanaSDK.Error.unknown
        }
    }()
    let walletAddressesData: String? = try {
        if token == .all {
            guard let solAddress = wallets.first(where: { $0.isNativeSOL })?.pubkey else {
                throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("SOL"))
            }
            let usdtAddress = wallets.first(where: { $0.token.address == "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB" })?.pubkey
            let dataStruct = WalletAddressesData(
                    networks: .init(solana: .init(address: solAddress)),
                    coins: .init(USDT: usdtAddress == nil ? nil : .init(address: usdtAddress!), SOL: .init(address: solAddress))
            )
            let data = try JSONEncoder().encode(dataStruct)
            let string = String(data: data, encoding: .utf8)
            return string!
        }
        return nil
    }()

    switch type {
    case .transak:
        // Create TransakProvider
        return TransakProvider(
                environment: {
                    if Defaults.apiEndPoint.network == .mainnetBeta {
                        return .production
                    } else {
                        return .staging
                    }
                }(),
                networks: ["solana", "mainnet"],
                cryptoCurrencies: token.code,
                hostURL: "https://" + .secretConfig("TRANSAK_HOST_URL")!,
                apiKey: {
                    if Defaults.apiEndPoint.network == .mainnetBeta {
                        return .secretConfig("TRANSAK_PRODUCTION_API_KEY")!
                    } else {
                        return .secretConfig("TRANSAK_STAGING_API_KEY")!
                    }
                }(),
                defaultCryptoCurrency: defaultCryptoCurrency,
                walletAddress: walletAddress,
                walletAddressesData: walletAddressesData)
    case .moonpay:
        return MoonpayProvider(
                environment: {
                    if Defaults.apiEndPoint.network == .mainnetBeta {
                        return .production
                    } else {
                        return .staging
                    }
                }(),
                apiKey: {
                    if Defaults.apiEndPoint.network == .mainnetBeta {
                        return .secretConfig("MOONPAY_PRODUCTION_API_KEY")!
                    } else {
                        return .secretConfig("MOONPAY_STAGING_API_KEY")!
                    }
                }(),
                showOnlyCurrencies: token.code,
                defaultCurrencyCode: defaultCryptoCurrency,
                walletAddress: walletAddress,
                walletAddresses: walletAddressesData
        )
    }
}

private struct WalletAddressesData: Encodable {
    let networks: Networks
    let coins: Coins

    struct Networks: Encodable {
        let solana: Chain
    }

    struct Coins: Encodable {
        let USDT: Chain?
        let SOL: Chain
    }

    struct Chain: Encodable {
        let address: String
    }
}
