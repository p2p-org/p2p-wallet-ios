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
import Reachability
import Resolver
import Sell
import Send
import SolanaSwift
import SwiftyUserDefaults
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
        register { DefaultLogManager.shared }
            .implements(ErrorObserver.self)

        // Application warmup manager
        register {
            WarmupManager(processes: [
                RemoteConfigWarmupProcess(),
                TokenServiceWarmupProcess(),
            ])
        }.scope(.application)

        register {
            WalletSettings(provider: WalletSettingsUserDefaultsProvider())
        }.scope(.application)

        // AppEventHandler
        register { AppEventHandler() }
            .implements(AppEventHandlerType.self)
            .implements(ChangeNetworkResponder.self)
            .implements(ChangeLanguageResponder.self)
            .implements(ChangeThemeResponder.self)
            .scope(.application)

        // Storages
        register { KeychainStorage() }
            .implements(NameStorageType.self)
            .implements(SolanaAccountStorage.self)
            .implements(PincodeStorageType.self)
            .implements(PincodeSeedPhrasesStorage.self)
            .scope(.application)

        register { DeviceShareManagerImpl() }
            .implements(DeviceShareManager.self)
            .scope(.application)

        register { KeyAppTokenHttpProvider(client: .init(endpoint: GlobalAppState.shared.tokenEndpoint)) }
            .implements(KeyAppTokenProvider.self)
            .scope(.application)

        register {
            DeviceShareMigrationService(
                isWeb3AuthUser: resolve(UserWalletManager.self)
                    .$wallet
                    .map { wallet in
                        guard let wallet else { return nil }
                        return wallet.ethAddress != nil
                    }
                    .eraseToAnyPublisher(),
                hasDeviceShare: resolve(DeviceShareManager.self)
                    .deviceSharePublisher
                    .map { deviceShare in deviceShare != nil }
                    .eraseToAnyPublisher(),
                errorObserver: resolve()
            )
        }
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
            .implements(CurrentUserWallet.self)
            .scope(.application)

        // WalletMetadata
        register { LocalWalletMetadataProvider() }
            .scope(.application)

        register { RemoteWalletMetadataProvider() }
            .scope(.application)

        register { TKeyWalletMetadataProvider() }
            .scope(.application)

        register {
            WalletMetadataServiceImpl(
                currentUserWallet: resolve(),
                errorObserver: resolve(),
                localMetadataProvider: resolve(LocalWalletMetadataProvider.self),
                remoteMetadataProvider: [
                    resolve(RemoteWalletMetadataProvider.self),
                    resolve(TKeyWalletMetadataProvider.self),
                ]
            )
        }
        .implements(WalletMetadataService.self)
        .scope(.session)

        // Prices
        register {
            PriceServiceImpl(api: resolve(), errorObserver: resolve())
        }
        .implements(PriceService.self)
        .scope(.application)

        register { WormholeRPCAPI(endpoint: GlobalAppState.shared.bridgeEndpoint) }
            .implements(WormholeAPI.self)
            .scope(.session)

        // AnalyticsManager
        register {
            let apiKey: String
            #if !RELEASE
                apiKey = .secretConfig("AMPLITUDE_API_KEY_FEATURE")!
            #else
                apiKey = .secretConfig("AMPLITUDE_API_KEY")!
            #endif

            return AmplitudeAnalyticsProvider(apiKey: apiKey)
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

        register {
            KeyAppSolanaTokenRepository(
                provider: resolve(),
                errorObserver: resolve()
            )
        }
        .implements(SolanaTokensService.self)
        .scope(.application)

        register { CreateNameServiceImpl() }
            .implements(CreateNameService.self)
            .scope(.application)

        register { EthereumTokensRepository(provider: resolve()) }
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

        // QrCodeImageRender
        register { QrCodeImageRenderImpl() }
            .implements(QrCodeImageRender.self)

        // Onboarding
        register { StartOnboardingNavigationProviderImpl() }
            .implements(StartOnboardingNavigationProvider.self)

        register { TKeyFacadeManagerImpl(analyticsManager: resolve()) }
            .implements(TKeyFacadeManager.self)
            .scope(.application)

        register { OnboardingServiceImpl() }
            .implements(OnboardingService.self)

        register { BiometricsAuthProviderImpl() }
            .implements(BiometricsAuthProvider.self)

        register { JWTTokenValidatorImpl() }
            .implements(JWTTokenValidator.self)

        register { AuthServiceBridge() }
            .implements(SocialAuthService.self)
            .scope(.application)

        register { Web3(rpcURL: String.secretConfig("ETH_RPC")!) }
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
                account: Resolver.resolve(SolanaAccountStorage.self).account
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
                memoPrefix: .secretConfig("SEND_VIA_LINK_MEMO_PREFIX")!,
                solanaAPIClient: resolve()
            )
        }
        .implements(SendViaLinkDataService.self)
        .scope(.session)

        // TransactionHandler (new)
        register { TransactionHandler() }
            .implements(TransactionHandlerType.self)
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
                        solanaTokenService: resolve(),
                        errorObserver: resolve(),
                        persistence: resolve()
                    ),
                    WormholeClaimUserActionConsumer(
                        address: userWalletManager.wallet?.ethereumKeypair.address,
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

        register {
            SolanaAccountsService(
                accountStorage: resolve(),
                solanaAPIClient: resolve(),
                tokensService: resolve(),
                priceService: resolve(),
                fiat: Defaults.fiat.rawValue,
                proxyConfiguration: nil,
                errorObservable: resolve()
            )
        }
        .scope(.session)

        register { () -> EthereumAccountsService in
            EthereumAccountsService(
                address: resolve(UserWalletManager.self).wallet?.ethereumKeypair.address ?? "",
                web3: resolve(),
                ethereumTokenRepository: resolve(),
                priceService: resolve(),
                fiat: Defaults.fiat.rawValue,
                errorObservable: resolve(),
                enable: available(.ethAddressEnabled)
            )
        }
        .scope(.session)

        register { FavouriteAccountsDataSource() }
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
                swapService: SwapServiceWrapper(
                    orcaSwap: resolve(),
                    relayService: resolve()
                )
            )
        }
        .implements(RecipientSearchService.self)
        .scope(.shared)

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
