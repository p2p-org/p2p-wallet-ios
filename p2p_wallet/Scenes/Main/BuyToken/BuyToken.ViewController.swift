//
//  BuyToken.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/09/2021.
//

import Foundation
import UIKit
import TransakSwift

extension BuyToken {
    class ViewController: WLIndicatorModalVC {
        // MARK: - Properties
        private let transakVC: TransakWidgetViewController
        private lazy var headerView = UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
            UILabel(text: L10n.buy, textSize: 17, weight: .semibold)
        ])
            .padding(.init(all: 20))
        
        // MARK: - Methods
        init(token: CryptoCurrency, repository: WalletsRepository) throws {
            let envAndParams = try getEnvironmentAndParams(token: token, repository: repository)
            transakVC = .init(env: envAndParams.0, params: envAndParams.1, loadingView: WLSpinnerView(size: 65, endColor: .h5887ff))
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
            
            add(child: transakVC, to: rootView)
        }
    }
}

private func getEnvironmentAndParams(token: BuyToken.CryptoCurrency, repository: WalletsRepository) throws -> (TransakWidgetViewController.Environment, TransakWidgetViewController.Params) {
    let environment: TransakWidgetViewController.Environment
    
    var params: [String: String] = [
        "networks": "solana,mainnet",
        "cryptoCurrencyList": token.code,
        "themeColor": "5887FF"
    ]
    
    let apiKey: String
    
    if Defaults.apiEndPoint.network == .mainnetBeta {
        environment = .production
        apiKey = Bundle.main.infoDictionary!["TRANSAK_PRODUCTION_API_KEY"] as! String

        params["hostURL"] = "https://" + (Bundle.main.infoDictionary!["TRANSAK_HOST_URL"] as! String)
    } else {
        environment = .staging
        apiKey = Bundle.main.infoDictionary!["TRANSAK_STAGING_API_KEY"] as! String
    }
    
    params["apiKey"] = apiKey
    
    let wallets = repository.getWallets()
    
    switch token {
    case .all:
        params["defaultCryptoCurrency"] = "SOL"
        
        let solAddress: String
        if let pubkey = wallets.first(where: {$0.isNativeSOL})?.pubkey
        {
            solAddress = pubkey
        } else {
            throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("SOL"))
        }
        
        let usdtAddress = wallets.first(where: {$0.token.address == "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"})?.pubkey
        
        let dataStruct = WalletAddressesData(
            networks: .init(solana: .init(address: solAddress)),
            coins: .init(USDT: usdtAddress == nil ? nil: .init(address: usdtAddress!), SOL: .init(address: solAddress))
        )
        
        let data = try JSONEncoder().encode(dataStruct)
        let string = String(data: data, encoding: .utf8)
        
        params["walletAddressesData"] = string
        
    case .sol:
        params["defaultCryptoCurrency"] = "SOL"
        
        let address: String
        if let pubkey = wallets.first(where: {$0.isNativeSOL})?.pubkey
        {
            address = pubkey
        } else {
            throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("SOL"))
        }
        params["walletAddress"] = address
    case .usdt:
        
        let address: String
        params["defaultCryptoCurrency"] = "USDT"
        if let pubkey = wallets.first(where: {$0.token.symbol == "USDT"})?.pubkey
        {
            address = pubkey
        }
//            else if let pubkey = wallets.first(where: {$0.token.isNative})?.pubkey {
//                address = pubkey
//            }
        else {
            throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("USDT"))
        }
        params["walletAddress"] = address
    default:
        throw SolanaSDK.Error.unknown
    }
    
    params["disableWalletAddressForm"] = "true"
    params["hideMenu"] = "true"
    
    return (environment, params)
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
