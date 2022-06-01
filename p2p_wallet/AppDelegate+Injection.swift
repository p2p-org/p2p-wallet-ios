//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import FeeRelayerSwift
import OrcaSwapSwift
import RenVMSwift
import Resolver
import SolanaSwift

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        // MARK: - Deprecated (REMOVE LATER)

        register { SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: Resolver.resolve()) }
            .scope(.session)

        register { SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl) }
            .implements(SocketType.self)
            .scope(.session)

        // MARK: - Lifetime app's services

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
        register { AnalyticsManager() }
            .implements(AnalyticsManagerType.self)
            .scope(.application)
        register { IntercomMessengerLauncher() }
            .implements(HelpCenterLauncher.self)
            .scope(.session)
        register { ImageSaver() }
            .implements(ImageSaverType.self)
            .scope(.unique)
        register { CryptoComparePricesFetcher() }
            .implements(PricesFetcher.self)
            .scope(.application)
        register { NameService(cache: NameServiceUserDefaultCache()) }
            .implements(NameServiceType.self)
            .scope(.application)
        register { LocalizationManager() }
            .implements(LocalizationManagerType.self)

        register { UserDefaultsPricesStorage() }
            .implements(PricesStorage.self)
            .scope(.application)
        register { CryptoComparePricesFetcher() }
            .implements(PricesFetcher.self)
            .scope(.application)
        register { NotificationServiceImpl() }
            .implements(NotificationService.self)
            .scope(.application)
        register { NotificationRepositoryImpl() }
            .implements(NotificationRepository.self)
            .scope(.application)
        register { ClipboardManager() }
            .implements(ClipboardManagerType.self)
            .scope(.application)

        // MARK: - Solana

        register { JSONRPCAPIClient(endpoint: Defaults.apiEndPoint) }
            .implements(SolanaAPIClient.self)
            .scope(.application)

        register { BlockchainClient(apiClient: resolve()) }
            .implements(SolanaBlockchainClient.self)

        // register { SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: Resolver.resolve()) }
        //     .implements(TokensRepository.self)
        //     .implements(TransactionsRepository.self)
        //     .implements(AssociatedTokenAccountHandler.self)
        //    .implements(RenVMSolanaAPIClientType.self)
        //     .implements(FeeAPIClient.self)
        //     .implements(OrcaSwapAccountProvider.self)
        //    .implements(OrcaSwapSignatureConfirmationHandler.self)
        //     .implements(ProcessTransactionAPIClient.self)
        //    .implements(FeeRelayerRelaySolanaClient.self)
        //     .scope(.session)

        // register { OrcaSwapSwift.APIClient(configsProvider: .init("mainnet")) }
        //     .implements(OrcaSwapSwift.OrcaSwapAPIClient.self)
        //     .scope(.session)

        // MARK: - Send service

        register { _, args in
            SendService(relayMethod: args())
        }
        .implements(SendServiceType.self)
        .scope(.session)

        // MARK: - Fee service

        register { FeeService() }
            .implements(FeeServiceType.self)
            .scope(.session)

        // MARK: - Socket

//        register { SolanaSD.Socket(url: URL(string: Defaults.apiEndPoint.socketUrl)!,enableDebugLogs: true) }
//            .implements(SocketType.self)
//            .scope(.session)

        // MARK: - TransactionHandler (new)

        register { TransactionHandler() }
            .implements(TransactionHandlerType.self)
            .scope(.session)

        register { SwapTransactionAnalytics(analyticsManager: resolve(), transactionHandler: resolve()) }
            .scope(.session)

        // MARK: - FeeRelayer

        register { FeeRelayerSwift.APIClient(version: 1) }
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

//        register { try! FeeRelayer.Relay(
//            apiClient: resolve(),
//            solanaClient: resolve(),
//            accountStorage: resolve(SolanaSDK.self).accountStorage,
//            orcaSwapClient: resolve(),
//            deviceType: .iOS,
//            buildNumber: Bundle.main.fullVersionNumber
//        ) }
//        .implements(FeeRelayerRelayType.self)
//        .scope(.session)

        // MARK: - PricesService

        register { PricesService() }
            .implements(PricesServiceType.self)
            .scope(.session)

        // MARK: - WalletsViewModel

        register { WalletsViewModel() }
            .implements(WalletsRepository.self)
            .implements(WLNotificationsRepository.self)
            .scope(.session)

        // MARK: - Swap

        register { SwapServiceWithRelayImpl() }
            .implements(Swap.Service.self)
            .scope(.session)

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

        // MARK: - RenVM

        register { RpcClient(network: Defaults.apiEndPoint.network == .mainnetBeta ? .mainnet : .testnet) }
            .implements(RenVMRpcClientType.self)
            .scope(.session)

        register {
            LockAndMint.Service(
                rpcClient: resolve(),
                solanaClient: resolve(),
                account: resolve(SolanaAccountStorage.self).account!,
                sessionStorage: LockAndMint.SessionStorage()
            )
        }
        .implements(RenVMLockAndMintServiceType.self)
        .scope(.session)

        register { BurnAndRelease.Service() }
            .implements(RenVMBurnAndReleaseServiceType.self)
            .scope(.session)

        // MARK: - Others

        register { DAppChannel() }
            .implements(DAppChannelType.self)

        // MARK: - Moonpay

        register { Moonpay.Provider(api: Moonpay.API.fromEnvironment()) }
            .scope(.shared)

        // MARK: - BuyProvider

        register { Buy.MoonpayBuyProcessingFactory() }
            .implements(BuyProcessingFactory.self)
            .scope(.application)

        register { Buy.MoonpayExchange(provider: resolve()) }
            .implements(Buy.ExchangeService.self)
            .scope(.session)

        // MARK: - AppEventHandler

        register { AppEventHandler() }
            .implements(AppEventHandlerType.self)
            .implements(DeviceOwnerAuthenticationHandler.self)
            .implements(ChangeNetworkResponder.self)
            .implements(ChangeLanguageResponder.self)
            .implements(LogoutResponder.self)
            .implements(CreateOrRestoreWalletHandler.self)
            .implements(OnboardingHandler.self)
            .scope(.application)

        // MARK: - AuthenticationHandler

        register { AuthenticationHandler() }
            .implements(AuthenticationHandlerType.self)
            .scope(.session)

        register { ReceiveToken.QrCodeImageRenderImpl() }
            .implements(QrCodeImageRender.self)
            .scope(.application)

        // MARK: - Banner

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

        // MARK: - RenBTCStatusService

        register { RenBTCStatusService() }
            .implements(RenBTCStatusServiceType.self)
            .scope(.session)

        // MARK: - HttpClient

        register { HttpClientImpl() }
            .implements(HttpClient.self)
            .scope(.session)
    }
}

extension ResolverScope {
    static let session = ResolverScopeCache()
}
