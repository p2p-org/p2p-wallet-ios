//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import AnalyticsManager
import CountriesAPI
import FeeRelayerSwift
import FirebaseRemoteConfig
import History
import Jupiter
import KeyAppBusiness
import KeyAppKitCore
import Moonpay
import NameService
import Onboarding
import OrcaSwapSwift
import P2PSwift
import Reachability
import Resolver
import Sell
import Send
import SolanaPricesAPIs
import SolanaSwift
import Solend
import SwiftyUserDefaults
import TransactionParser
import Web3
import Wormhole

extension Resolver: ResolverRegistering {
    @MainActor public static func registerAllServices() {
        registerForApplicationScope()

        registerForGraphScope()

        registerForSessionScope()

        registerForSharedScope()
    }

    // MARK: - Helpers

    /// Application scope: Lifetime app's services
    @MainActor private static func registerForApplicationScope() {
        register { SentryErrorObserver() }
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
        register { RemoteWalletMetadataProvider() }
        register {
            WalletMetadataService(
                localProvider: resolve(LocalWalletMetadataProvider.self),
                remoteProvider: resolve(RemoteWalletMetadataProvider.self)
            )
        }
        .scope(.application)

        // Prices
        register { SolanaPriceService(api: resolve()) }
            .scope(.application)

        register { EthereumPriceService(api: resolve()) }
            .scope(.application)

        register { WormholeRPCAPI(endpoint: GlobalAppState.shared.bridgeEndpoint) }
            .implements(WormholeAPI.self)
            .scope(.application)

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

    /// Graph scope: Recreate and reuse dependencies
    @MainActor private static func registerForGraphScope() {
        // Intercom
        register { IntercomMessengerLauncher() }
            .implements(HelpCenterLauncher.self)

        // ImageSaver
        register { ImageSaver() }
            .implements(ImageSaverType.self)

        // NameService
        register { NameServiceImpl(
            endpoint: GlobalAppState.shared.nameServiceEndpoint,
            cache: NameServiceUserDefaultCache()
        ) }
        .implements(NameService.self)

        register { NameServiceUserDefaultCache() }
            .implements(NameServiceCacheType.self)

        // ClipboardManager
        register { ClipboardManager() }
            .implements(ClipboardManagerType.self)

        // LocalizationManager
        register { LocalizationManager() }
            .implements(LocalizationManagerType.self)

        // SolanaAPIClient
        register { JSONRPCAPIClient(endpoint: Defaults.apiEndPoint) }
            .implements(SolanaAPIClient.self)

        // SolanaBlockchainClient
        register { BlockchainClient(apiClient: resolve()) }
            .implements(SolanaBlockchainClient.self)

        register { TokensRepository(
            endpoint: Defaults.apiEndPoint,
            tokenListParser: .init(url: RemoteConfig.remoteConfig()
                .tokenListURL ??
                "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/src/tokens/solana.tokenlist.json"),
            cache: resolve()
        ) }
        .implements(SolanaTokensRepository.self)
        .scope(.application)

        // QrCodeImageRender
        register { ReceiveToken.QrCodeImageRenderImpl() }
            .implements(QrCodeImageRender.self)

        // Navigation provider
        register { StartOnboardingNavigationProviderImpl() }
            .implements(StartOnboardingNavigationProvider.self)

        register { OnboardingServiceImpl() }
            .implements(OnboardingService.self)

        register { BiometricsAuthProviderImpl() }
            .implements(BiometricsAuthProvider.self)

        register { JWTTokenValidatorImpl() }
            .implements(JWTTokenValidator.self)

        register { Web3(rpcURL: "https://eth-mainnet.g.alchemy.com/v2/a3NxxBPY4WUcsXnivRq-ikYKXFB67oXm") }
    }

    /// Session scope: Live when user is authenticated
    @MainActor private static func registerForSessionScope() {
        register {
            let userWalletsManager: UserWalletManager = resolve()

            return WormholeService(
                api: resolve(),
                ethereumKeypair: userWalletsManager.wallet?.ethereumKeypair,
                solanaKeyPair: userWalletsManager.wallet?.account,
                errorObservable: resolve()
            )
        }
        .scope(.session)

        // AuthenticationHandler
        register { AuthenticationHandler() }
            .implements(AuthenticationHandlerType.self)
            .scope(.session)

        register { UserSessionCache() }
            .scope(.session)

        register { PincodeServiceImpl() }
            .implements(PincodeService.self)
            .scope(.session)

        // SendService
        register { SendHistoryLocalProvider() }
            .scope(.session)

        register {
            SendActionServiceImpl(
                contextManager: Resolver.resolve(),
                solanaAPIClient: Resolver.resolve(),
                blockchainClient: Resolver.resolve(),
                relayService: Resolver.resolve(),
                account: Resolver.resolve(AccountStorageType.self).account
            )
        }
        .implements(SendActionService.self)
        .scope(.session)

        register {
            SendHistoryService(provider: resolve(SendHistoryLocalProvider.self))
        }
        .scope(.session)

        // SendViaLink
        register {
            SendViaLinkDataServiceImpl(
                salt: .secretConfig("SEND_VIA_LINK_SALT")!,
                passphrase: "",
                network: .mainnetBeta,
                derivablePath: .default,
                host: "t.key.app",
                solanaAPIClient: resolve()
            )
        }
        .implements(SendViaLinkDataService.self)
        .scope(.session)

        // SolanaSocket
        register { Socket(url: URL(string: Defaults.apiEndPoint.socketUrl)!) }
            .implements(SolanaSocket.self)
            .scope(.session)

        // AccountObservableService
        register { SolananAccountsObservableServiceImpl(solanaSocket: resolve()) }
            .implements(SolanaAccountsObservableService.self)
            .scope(.session)

        // TransactionHandler (new)
        register { TransactionHandler() }
            .implements(TransactionHandlerType.self)
            .scope(.session)

        // SwapTransactionAnalytics
        register { SwapTransactionAnalytics(analyticsManager: resolve(), transactionHandler: resolve()) }
            .scope(.session)

        // FeeRelayer
        register { FeeRelayerSwift.APIClient(baseUrlString: FeeRelayerEndpoint.baseUrl, version: 1) }
            .implements(FeeRelayerAPIClient.self)
            .scope(.session)

        // UserActionService
        register { UserActionPersistentStorageWithUserDefault(errorObserver: resolve()) }
            .implements(UserActionPersistentStorage.self)
            .scope(.application)

        register {
            let userWalletManager: UserWalletManager = resolve()

            return UserActionService(
                consumers: [
                    WormholeSendUserActionConsumer(
                        address: userWalletManager.wallet?.account.publicKey.base58EncodedString,
                        signer: userWalletManager.wallet?.account,
                        solanaClient: resolve(),
                        wormholeAPI: resolve(),
                        relayService: resolve(),
                        errorObserver: resolve(),
                        persistence: resolve()
                    ),
                    WormholeClaimUserActionConsumer(
                        address: userWalletManager.wallet?.ethereumKeypair.publicKey,
                        signer: userWalletManager.wallet?.ethereumKeypair,
                        wormholeAPI: resolve(),
                        ethereumTokenRepository: resolve(),
                        errorObserver: resolve(),
                        persistence: resolve()
                    ),
                ]
            )
        }
        .scope(.session)

        register { RelayServiceImpl(
            contextManager: resolve(),
            orcaSwap: resolve(),
            accountStorage: resolve(),
            solanaApiClient: resolve(),
            feeCalculator: DefaultRelayFeeCalculator(),
            feeRelayerAPIClient: resolve(),
            deviceType: .iOS,
            buildNumber: Bundle.main.fullVersionNumber,
            environment: Environment.current == .release ? .release : .dev
        ) }
        .implements(RelayService.self)
        .scope(.session)

        register { () -> RelayContextManager in
            if FeeRelayConfig.shared.disableFeeTransaction {
                return RelayContextManagerDisabledFreeTrxImpl(
                    accountStorage: resolve(),
                    solanaAPIClient: resolve(),
                    feeRelayerAPIClient: resolve()
                )
            } else {
                return RelayContextManagerImpl(
                    accountStorage: resolve(),
                    solanaAPIClient: resolve(),
                    feeRelayerAPIClient: resolve()
                )
            }
        }
        .scope(.session)

        register {
            DefaultSwapFeeRelayerCalculator(
                destinationAnalysator: DestinationAnalysatorImpl(solanaAPIClient: Resolver.resolve()),
                accountStorage: Resolver.resolve()
            )
        }
        .implements(SwapFeeRelayerCalculator.self)
        .scope(.session)

        // PricesService
        register { PricesService() }
            .implements(PricesServiceType.self)
            .implements(SellPriceProvider.self)
            .scope(.session)

        // WalletsViewModel
        register { WalletsRepositoryImpl() }
            .implements(WalletsRepository.self)
            .scope(.session)

        register {
            SolanaAccountsService(
                accountStorage: resolve(),
                solanaAPIClient: resolve(),
                tokensService: resolve(),
                priceService: resolve(),
                accountObservableService: resolve(),
                fiat: Defaults.fiat.rawValue,
                errorObservable: resolve()
            )
        }
        .scope(.session)

        register {
            EthereumAccountsService(
                address: resolve(UserWalletManager.self).wallet?.ethereumKeypair.address ?? "",
                web3: resolve(),
                ethereumTokenRepository: resolve(),
                priceService: resolve(),
                fiat: Defaults.fiat.rawValue,
                errorObservable: resolve()
            )
        }
        .scope(.session)

        register { FavouriteAccountsDataSource() }
            .scope(.session)

        // SwapService
        register { SwapServiceWithRelayImpl() }
            .implements(SwapServiceType.self)
            .scope(.session)

        // OrcaSwapSwift
        register { OrcaSwapSwift.NetworkConfigsProvider(network: Defaults.apiEndPoint.network.cluster) }
            .implements(OrcaSwapConfigsProvider.self)

        register { OrcaSwapSwift.APIClient(configsProvider: resolve()) }
            .implements(OrcaSwapAPIClient.self)

        register {
            OrcaSwap(
                apiClient: resolve(),
                solanaClient: resolve(),
                blockchainClient: resolve(),
                accountStorage: resolve()
            )
        }
        .implements(OrcaSwapType.self)
        .scope(.session)

        // HttpClient
        register { HttpClientImpl() }
            .implements(HttpClient.self)
            .scope(.session)

        // Auth
        register { AuthServiceImpl() }
            .implements(AuthService.self)
            .scope(.session)

        // Sell
        register { SellTransactionsRepositoryImpl() }
            .implements(SellTransactionsRepository.self)
            .scope(.session)

        register {
            MoonpaySellDataServiceProvider(moonpayAPI: resolve())
        }
        .implements((any SellDataServiceProvider).self)
        .scope(.session)

        register {
            MoonpaySellActionServiceProvider(moonpayAPI: resolve())
        }
        .implements((any SellActionServiceProvider).self)
        .scope(.session)

        register {
            MoonpaySellDataService(
                userId: Resolver.resolve(UserWalletManager.self).wallet?.moonpayExternalClientId ?? "",
                provider: resolve(),
                priceProvider: resolve(),
                sellTransactionsRepository: resolve()
            )
        }
        .implements((any SellDataService).self)
        .scope(.session)

        register {
            let endpoint: String
            let apiKey: String
            switch Defaults.moonpayEnvironment {
            case .production:
                endpoint = .secretConfig("MOONPAY_PRODUCTION_SELL_ENDPOINT")!
                apiKey = .secretConfig("MOONPAY_PRODUCTION_API_KEY")!
            case .sandbox:
                endpoint = .secretConfig("MOONPAY_STAGING_SELL_ENDPOINT")!
                apiKey = .secretConfig("MOONPAY_STAGING_API_KEY")!
            }

            return MoonpaySellActionService(
                provider: resolve(),
                refundWalletAddress: Resolver.resolve(UserWalletManager.self).wallet?.account.publicKey
                    .base58EncodedString ?? "",
                endpoint: endpoint,
                apiKey: apiKey
            )
        }
        .implements((any SellActionService).self)
        .scope(.session)

        register {
            JupiterTokensRepositoryImpl(
                provider: resolve(),
                jupiterClient: resolve()
            )
        }
        .implements(JupiterTokensRepository.self)
        .scope(.session)

        register {
            JupiterRestClientAPI(
                host: GlobalAppState.shared.newSwapEndpoint,
                tokensHost: GlobalAppState.shared
                    .newSwapEndpoint == "https://quote-api.jup.ag" ? "https://cache.jup.ag" : nil,
                version: .v4
            )
        }
        .implements(JupiterAPI.self)
        .scope(.session)

        register {
            JupiterTokensLocalProvider()
        }
        .implements(JupiterTokensProvider.self)
        .scope(.session)
    }

    /// Shared scope: share between screens
    private static func registerForSharedScope() {
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

extension ResolverScope {
    static let session = ResolverScopeCache()
}
