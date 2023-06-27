import Foundation
import Resolver
import Moonpay
import Send
import Solend
import P2PSwift

extension Resolver {
    /// Shared scope: share between screens
    static func registerForSharedScope() {
        // BuyServices
        register {
            Moonpay
                .Provider(api: Moonpay.API.fromEnvironment(), serverSideAPI: Moonpay.API.fromEnvironment(kind: .server))
        }
        .scope(.shared)
        
        register { Buy.MoonpayBuyProcessingFactory() }
            .implements(BuyProcessingFactory.self)
            .scope(.application)
        
        register { MoonpayExchange(provider: resolve()) }
            .implements(BuyExchangeService.self)
            .scope(.shared)
        
        // Buy
        register {
            RecipientSearchServiceImpl(
                nameService: resolve(),
                solanaClient: resolve(),
                swapService: SwapServiceWrapper()
            )
        }
        .implements(RecipientSearchService.self)
        .scope(.shared)
        
        // Solend
        register { SolendFFIWrapper() }
            .implements(Solend.self)
            .scope(.application)
        register {
            SolendDataServiceImpl(
                solend: resolve(),
                owner: resolve(AccountStorageType.self).account!,
                lendingMark: "4UpD2fh7xH3VP9QQaXtsS1YY3bxzWhtfpks7FatyKvdY",
                cache: resolve(UserSessionCache.self)
            )
        }
        .implements(SolendDataService.self)
        .scope(.session)
        
        register {
            SolendActionServiceImpl(
                rpcUrl: Defaults.apiEndPoint.getURL(),
                lendingMark: "4UpD2fh7xH3VP9QQaXtsS1YY3bxzWhtfpks7FatyKvdY",
                userAccountStorage: resolve(),
                solend: resolve(),
                solana: resolve(),
                feeRelayApi: resolve(),
                relayService: resolve(),
                relayContextManager: resolve()
            )
        }
        .implements(SolendActionService.self)
        .scope(.session)
        
        // Solana tracker
        register {
            SolanaTrackerImpl(
                solanaNegativeStatusFrequency: nil,
                solanaNegativeStatusPercent: nil,
                solanaNegativeStatusTimeFrequency: nil
            )
        }
        .implements(SolanaTracker.self)
        .scope(.shared)
    }
}
