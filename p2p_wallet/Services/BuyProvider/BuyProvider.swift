//
// Created by Giang Long Tran on 21.10.21.
//

import Foundation

public protocol BuyProvider {
    func getUrl() -> String
}

protocol BuyProviderFactory {
    func create(
        walletRepository: WalletsRepository,
        crypto: BuyProviders.Crypto,
        initialAmount: Double,
        currency: BuyProviders.Currency
    ) throws -> BuyProvider
}

struct BuyProviders {
    enum Currency: String {
        case usd = "usd"
    }
    
    enum Crypto: String {
        case eth = "eth"
        case sol = "sol"
        case usdt = "usdt"
        
        static let all: Set<Crypto> = [.eth, .sol, .usdt]
        
        func toWallet() -> String {
            switch self {
            case .eth: return "ETH"
            case .sol: return "SOL"
            case .usdt: return "USDT"
            }
        }
    }
    
    class MoonpayFactory: BuyProviderFactory {
        func create(walletRepository: WalletsRepository, crypto: Crypto, initialAmount: Double, currency: Currency) throws -> BuyProvider {
//            guard let walletAddress = walletRepository.getWallets().first(where: { $0.token.symbol == crypto.toWallet() })?.pubkey else {
//                throw SolanaSDK.Error.other(L10n.thereIsNoWalletInYourAccount("ETH"))
//            }
            
            return MoonpayProvider(
                environment: Defaults.apiEndPoint.network == .mainnetBeta ?
                    .production :
                    .staging,
                apiKey: Defaults.apiEndPoint.network == .mainnetBeta ?
                    .secretConfig("MOONPAY_PRODUCTION_API_KEY")! :
                    .secretConfig("MOONPAY_STAGING_API_KEY")!,
                currencyCode: crypto.rawValue,
                walletAddress: walletRepository.nativeWallet?.pubkey,
                baseCurrencyCode: currency.rawValue,
                baseCurrencyAmount: initialAmount
            )
        }
    }
}
