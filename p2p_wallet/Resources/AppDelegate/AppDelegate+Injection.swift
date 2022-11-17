//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import AnalyticsManager
import CountriesAPI
import FeeRelayerSwift
import NameService
import Onboarding
import OrcaSwapSwift
import P2PSwift
import Reachability
import RenVMSwift
import Resolver
import SolanaPricesAPIs
import SolanaSwift
import Solend
import SwiftyUserDefaults
import FirebaseRemoteConfig
import Send

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        registerForApplicationScope()

        registerForGraphScope()

        registerForSessionScope()

        registerForSharedScope()
    }

    // MARK: - Helpers

    /// Application scope: Lifetime app's services
    private static func registerForApplicationScope() {
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
        }.scope(.application)

        // AnalyticsManager
        register { AnalyticsManagerImpl(apiKey: .secretConfig("AMPLITUDE_API_KEY")!) }
            .implements(AnalyticsManager.self)
            .scope(.application)

        // NotificationManager
        register(Reachability.self) {
            let reachability = try! Reachability()
            try! reachability.startNotifier()
            return reachability
        }
        .scope(.application)

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
        register { UserDefaultsPricesStorage() }
            .implements(PricesStorage.self)
            .scope(.application)

        if !Defaults.isCoingeckoProviderDisabled {
            register { CoinGeckoPricesAPI() }
                .implements(SolanaPricesAPI.self)
                .scope(.application)
        } else {
            register { CryptoComparePricesAPI(apikey: .secretConfig("CRYPTO_COMPARE_API_KEY")) }
                .implements(SolanaPricesAPI.self)
                .scope(.application)
        }

        register { InMemoryTokensRepositoryCache() }
            .implements(SolanaTokensRepositoryCache.self)
            .scope(.application)

        register { CreateNameServiceImpl() }
            .implements(CreateNameService.self)
            .scope(.application)
    }

    /// Graph scope: Recreate and reuse dependencies
    private static func registerForGraphScope() {
        // Intercom
        register { IntercomMessengerLauncher() }
            .implements(HelpCenterLauncher.self)

        // ImageSaver
        register { ImageSaver() }
            .implements(ImageSaverType.self)

        // NameService
        register { NameServiceImpl(
            endpoint: NameServiceImpl.endpoint,
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
            tokenListParser: .init(url: RemoteConfig.remoteConfig().tokenListURL ?? "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/src/tokens/solana.tokenlist.json"),
            cache: resolve()
        )}
            .implements(SolanaTokensRepository.self)

        // DAppChannnel
        register { DAppChannel() }
            .implements(DAppChannelType.self)

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
    }

    /// Session scope: Live when user is authenticated
    private static func registerForSessionScope() {
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
        register { _, args in
            SendService(relayMethod: args())
        }
        .implements(SendServiceType.self)
        .scope(.session)

        // SolanaSocket
        register { Socket(url: URL(string: Defaults.apiEndPoint.socketUrl)!) }
            .implements(SolanaSocket.self)
            .scope(.session)

        // AccountObservableService
        register { AccountsObservableServiceImpl(solanaSocket: resolve()) }
            .implements(AccountObservableService.self)
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

        register { FeeRelayerService(
            orcaSwap: resolve(),
            accountStorage: resolve(),
            solanaApiClient: resolve(),
            feeCalculator: DefaultFreeRelayerCalculator(),
            feeRelayerAPIClient: resolve(),
            deviceType: .iOS,
            buildNumber: Bundle.main.fullVersionNumber
        ) }
        .implements(FeeRelayer.self)
        .scope(.session)

        register {
            SwapFeeRelayerImpl(
                accountStorage: resolve(),
                feeRelayerAPIClient: resolve(),
                solanaApiClient: resolve(),
                orcaSwap: resolve()
            )
        }
        .implements(SwapFeeRelayer.self)

        register { () -> FeeRelayerContextManager in
            if FeeRelayConfig.shared.disableFeeTransaction {
                return FeeRelayerContextManagerDisabledFreeTrxImpl(
                    accountStorage: resolve(),
                    solanaAPIClient: resolve(),
                    feeRelayerAPIClient: resolve()
                )
            } else {
                return FeeRelayerContextManagerImpl(
                    accountStorage: resolve(),
                    solanaAPIClient: resolve(),
                    feeRelayerAPIClient: resolve()
                )
            }
        }

        // PricesService
        register { PricesService() }
            .implements(PricesServiceType.self)
            .scope(.session)

        // WalletsViewModel
        register { WalletsViewModel() }
            .implements(WalletsRepository.self)
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

        // RenVMSwift
        register { RenVMSwift.RpcClient(network: Defaults.apiEndPoint.network == .mainnetBeta ? .mainnet : .testnet) }
            .implements(RenVMRpcClientType.self)
            .scope(.session)

        register { RenVMSolanaChainProvider() }
            .implements(RenVMSwift.ChainProvider.self)

        register {
            UserDefaultsBurnAndReleasePersistentStore(
                userDefaultKeyForSubmitedBurnTransactions: BurnAndRelease.keyForSubmitedBurnTransaction
            )
        }
        .implements(BurnAndReleasePersistentStore.self)

        register {
            BurnAndReleaseServiceImpl(
                rpcClient: resolve(),
                chainProvider: resolve(),
                destinationChain: .bitcoin,
                persistentStore: resolve(),
                version: "1"
            )
        }
        .implements(BurnAndReleaseService.self)

        register {
            UserDefaultLockAndMintServicePersistentStore(
                userDefaultKeyForSession: LockAndMint.keyForSession,
                userDefaultKeyForGatewayAddress: LockAndMint.keyForGatewayAddress,
                userDefaultKeyForProcessingTransactions: LockAndMint.keyForProcessingTransactions,
                showLog: true
            )
        }
        .implements(LockAndMintServicePersistentStore.self)

        register {
            LockAndMintServiceImpl(
                persistentStore: resolve(),
                chainProvider: resolve(),
                rpcClient: resolve(),
                mintToken: .bitcoin,
                showLog: true
            )
        }
        .implements(LockAndMintService.self)
        .scope(.session)

        // RenBTCStatusService
        register { RenBTCStatusService() }
            .implements(RenBTCStatusServiceType.self)
            .scope(.session)

        // HttpClient
        register { HttpClientImpl() }
            .implements(HttpClient.self)
            .scope(.session)

        // Auth
        register { AuthServiceImpl() }
            .implements(AuthService.self)
            .scope(.session)
    }

    /// Shared scope: share between screens
    private static func registerForSharedScope() {
        // BuyServices
        register { Moonpay.Provider(api: Moonpay.API.fromEnvironment()) }
            .scope(.shared)

        register { Buy.MoonpayBuyProcessingFactory() }
            .implements(BuyProcessingFactory.self)
            .scope(.application)

        register { Buy.MoonpayExchange(provider: resolve()) }
            .implements(Buy.ExchangeService.self)
            .scope(.session)

        register { MoonpayExchange(provider: resolve()) }
            .implements(BuyExchangeService.self)
            .scope(.session)
        
        // Buy
        register { RecipientSearchServiceImpl(nameService: resolve()) }
            .implements(RecipientSearchService.self)
            .scope(.session)

        // Banner
        register {
            BannerServiceImpl(handlers: [
                ReserveNameBannerHandler(nameStorage: resolve()),
                BackupBannerHandler(backupStorage: resolve()),
                FeedbackBannerHandler(),
                // NotificationBannerHandler()
            ])
        }
        .implements(Banners.Service.self)
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
                feeRelay: resolve(),
                feeRelayContextManager: resolve()
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
