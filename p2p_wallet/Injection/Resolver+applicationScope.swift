import Foundation
import Resolver
import KeyAppBusiness
import KeyAppKitCore
import NameService
import AnalyticsManager
import TransactionParser
import SolanaPricesAPIs
import CountriesAPI
import SolanaSwift
import Reachability
import Wormhole
import History
import Onboarding

extension Resolver {
    /// Application scope: Lifetime app's services
    @MainActor static func registerForApplicationScope() {
        register { DefaultLogManager.shared }
            .implements(ErrorObserver.self)
        
        // Application warmup manager
        register {
            WarmupManager(processes: [
                RemoteConfigWarmupProcess(),
            ])
        }.scope(.application)
        
        register {
            WalletSettings(provider: WalletSettingsUserDefaultsProvider())
        }.scope(.application)
        
        // AppEventHandler
        register { AppEventHandler() }
            .implements(AppEventHandlerType.self)
            .implements(DeviceOwnerAuthenticationHandler.self)
            .implements(ChangeNetworkResponder.self)
            .implements(ChangeLanguageResponder.self)
            .implements(ChangeThemeResponder.self)
            .scope(.application)
        
        // Storages
        register { KeychainStorage() }
            .implements(ICloudStorageType.self)
            .implements(NameStorageType.self)
            .implements(SolanaAccountStorage.self)
            .implements(PincodeStorageType.self)
            .implements(AccountStorageType.self)
            .implements(PincodeSeedPhrasesStorage.self)
            .implements((AccountStorageType & NameStorageType).self)
            .implements((AccountStorageType & PincodeStorageType & NameStorageType).self)
            .implements((ICloudStorageType & AccountStorageType & NameStorageType).self)
            .implements((ICloudStorageType & AccountStorageType & NameStorageType & PincodeStorageType).self)
            .scope(.application)
        
        register { SendViaLinkStorageImpl() }
            .implements(SendViaLinkStorage.self)
            .scope(.session)
        
        // API Gateway
        register { () -> APIGatewayClient in
#if !RELEASE
            let apiGatewayEndpoint = String.secretConfig("API_GATEWAY_DEV")!
#else
            let apiGatewayEndpoint = String.secretConfig("API_GATEWAY_PROD")!
#endif
            
            return available(.mockedApiGateway) ?
            APIGatewayClientImplMock() :
            APIGatewayClientImpl(endpoint: apiGatewayEndpoint)
        }
        
        // WalletManager
        register { UserWalletManager() }
            .scope(.application)
        
        // WalletMetadata
        register { LocalWalletMetadataProvider() }
            .scope(.application)
        
        register { RemoteWalletMetadataProvider() }
            .scope(.application)
        
        register {
            WalletMetadataService(
                localProvider: resolve(LocalWalletMetadataProvider.self),
                remoteProvider: resolve(RemoteWalletMetadataProvider.self)
            )
        }
        .scope(.session)
        
        // Prices
        register { SolanaPriceService(api: resolve()) }
            .scope(.application)
        
        register { EthereumPriceService(api: resolve()) }
            .scope(.application)
        
        register { WormholeRPCAPI(endpoint: GlobalAppState.shared.bridgeEndpoint) }
            .implements(WormholeAPI.self)
            .scope(.session)
        
        // AnalyticsManager
        register {
            AmplitudeAnalyticsProvider()
        }
        .scope(.application)
        
        register {
            AppsFlyerAnalyticsProvider()
        }
        .scope(.application)
        
        register {
            FirebaseAnalyticsProvider()
        }
        .scope(.application)
        
        register {
            AnalyticsManagerImpl(providers: [
                resolve(AmplitudeAnalyticsProvider.self),
                resolve(AppsFlyerAnalyticsProvider.self),
                resolve(FirebaseAnalyticsProvider.self),
            ])
        }
        .implements(AnalyticsManager.self)
        .scope(.application)
        
        // NotificationManager
        register(Reachability.self) {
            let reachability = try! Reachability()
            try! reachability.startNotifier()
            return reachability
        }
        .scope(.application)
        
        // History
        register {
            DefaultTransactionParserRepository(
                p2pFeePayers: ["FG4Y3yX4AAchp1HvNZ7LfzFTewF2f6nDoMDCohTFrdpT"],
                parser: TransactionParserServiceImpl.default(apiClient: Resolver.resolve())
            )
        }
        .implements(TransactionParsedRepository.self)
        .scope(.application)
        
        register { KeyAppHistoryProviderImpl(endpoint: GlobalAppState.shared.pushServiceEndpoint) }
            .implements(KeyAppHistoryProvider.self)
            .scope(.session)
        
        register { NotificationServiceImpl() }
            .implements(NotificationService.self)
            .scope(.application)
        
        register { CountriesAPIImpl() }
            .implements(CountriesAPI.self)
            .scope(.application)
        
        register { NotificationRepositoryImpl() }
            .implements(NotificationRepository.self)
            .scope(.application)
        
        // PricesService
        register { InMemoryPricesStorage() }
            .implements(PricesStorage.self)
            .scope(.application)
        
        register { CoinGeckoPricesAPI() }
            .implements(SolanaPricesAPI.self)
            .scope(.application)
        
        register { InMemoryTokensRepositoryCache() }
            .implements(SolanaTokensRepositoryCache.self)
            .scope(.application)
        
        register { CreateNameServiceImpl() }
            .implements(CreateNameService.self)
            .scope(.application)
        
        register { EthereumTokensRepository(web3: resolve()) }
            .scope(.application)
    }
}
