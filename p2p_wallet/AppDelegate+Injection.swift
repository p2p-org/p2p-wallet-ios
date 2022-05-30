//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import FeeRelayerSwift
import RenVMSwift
import SolanaSwift

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
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

        // MARK: - SolanaSDK

        register { SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: Resolver.resolve()) }
            .implements(TokensRepository.self)
            .implements(TransactionsRepository.self)
            .implements(AssociatedTokenAccountHandler.self)
//            .implements(RenVMSolanaAPIClientType.self)
            .implements(FeeAPIClient.self)
//            .implements(OrcaSwapAccountProvider.self)
//            .implements(OrcaSwapSignatureConfirmationHandler.self)
            .implements(ProcessTransactionAPIClient.self)
//            .implements(FeeRelayerRelaySolanaClient.self)
            .scope(.session)

//        register { OrcaSwapSwift.APIClient(configsProvider: .init()) }
//            .implements(OrcaSwapSwift.OrcaSwapAPIClient.self)

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

//        register { SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl) }
//            .implements(SocketType.self)
//            .scope(.session)

        // MARK: - TransactionHandler (new)

        register { TransactionHandler() }
            .implements(TransactionHandlerType.self)
            .scope(.session)

        register { SwapTransactionAnalytics(analyticsManager: resolve(), transactionHandler: resolve()) }
            .scope(.session)

        // MARK: - FeeRelayer

//        register { FeeRelayer.APIClient(version: 1) }
//            .implements(FeeRelayerAPIClientType.self)
//            .scope(.session)
//
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

//        register {
//            OrcaSwap(
//                apiClient: OrcaSwapSwift.APIClient(
//                    network: Defaults.apiEndPoint.network.cluster
//                ),
//                solanaClient: resolve(),
//                accountProvider: resolve(),
//                notificationHandler: resolve()
//            )
//        }
//        .implements(OrcaSwapType.self)
//        .scope(.session)

        // MARK: - RenVM

//        register { RpcClient(network: Defaults.apiEndPoint.network == .mainnetBeta ? .mainnet : .testnet) }
//            .implements(RenVMRpcClientType.self)
//            .scope(.session)

        register {
            RenVM.LockAndMint.Service(
                rpcClient: resolve(),
                solanaClient: resolve(),
                account: resolve(SolanaSDK.self).accountStorage.account!,
                sessionStorage: RenVM.LockAndMint.SessionStorage()
            )
        }
        .implements(RenVMLockAndMintServiceType.self)
        .scope(.session)

        register {
            RenVM.BurnAndRelease.Service(
                //                rpcClient: resolve(),
//                solanaClient: resolve(),
//                account: resolve(SolanaSDK.self).accountStorage.account!,
//                transactionStorage: RenVM.BurnAndRelease.TransactionStorage()
            )
        }
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
