//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import SolanaSwift
import FeeRelayerSwift
import OrcaSwapSwift

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        // MARK: - Lifetime app's services
        register { KeychainStorage() }
            .implements(ICloudStorageType.self)
            .implements(NameStorageType.self)
            .implements(SolanaSDKAccountStorage.self)
            .implements(PincodeStorageType.self)
            .implements(AccountStorageType.self)
            .implements(PincodeSeedPhrasesStorage.self)
            .implements((AccountStorageType & NameStorageType).self)
            .implements((AccountStorageType & PincodeStorageType & NameStorageType).self)
            .implements((ICloudStorageType & AccountStorageType & NameStorageType).self)
            .implements((ICloudStorageType & AccountStorageType & NameStorageType & PincodeStorageType).self)
            .scope(.application)
        register {AnalyticsManager()}
            .implements(AnalyticsManagerType.self)
            .scope(.application)
        register { IntercomMessengerLauncher() }
            .implements(HelpCenterLauncher.self)
            .scope(.session)
        register {CryptoComparePricesFetcher()}
            .implements(PricesFetcher.self)
            .scope(.application)
        register {NameService()}
            .implements(NameServiceType.self)
            .scope(.application)
        register { AddressFormatter() }
            .implements(AddressFormatterType.self)
            .scope(.application)
        register { LocalizationManager() }
            .implements(LocalizationManagerType.self)
        
        register { UserDefaultsPricesStorage() }
            .implements(PricesStorage.self)
            .scope(.application)
        register { CryptoComparePricesFetcher() }
            .implements(PricesFetcher.self)
            .scope(.application)
        register { NotificationsService() }
            .implements(NotificationsServiceType.self)
            .scope(.application)
        register { ClipboardManager() }
            .implements(ClipboardManagerType.self)
            .scope(.application)
        
        // MARK: - SolanaSDK
        register { SolanaSDK(endpoint: Defaults.apiEndPoint, accountStorage: Resolver.resolve()) }
            .implements(TokensRepository.self)
            .implements(TransactionsRepository.self)
            .implements(AssociatedTokenAccountHandler.self)
            .implements(RenVMSolanaAPIClientType.self)
            .implements(FeeAPIClient.self)
            .implements(OrcaSwapSolanaClient.self)
            .implements(OrcaSwapAccountProvider.self)
            .implements(OrcaSwapSignatureConfirmationHandler.self)
            .implements(ProcessTransactionAPIClient.self)
            .scope(.session)
        
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
        register { SolanaSDK.Socket(endpoint: Defaults.apiEndPoint.socketUrl) }
            .implements(AccountNotificationsRepository.self)
            .implements(TransactionHandler.self)
            .scope(.session)
        
        // MARK: - FeeRelayer
        register { FeeRelayer.APIClient(version: 1) }
            .implements(FeeRelayerAPIClientType.self)
            .scope(.session)
        
        register { try! FeeRelayer.Relay(
            apiClient: resolve(),
            solanaClient: resolve(),
            accountStorage: resolve(SolanaSDK.self).accountStorage,
            orcaSwapClient: resolve()
        ) }
            .implements(FeeRelayerRelayType.self)
            .scope(.session)
        
        // MARK: - PricesService
        register { PricesService() }
            .implements(PricesServiceType.self)
            .scope(.session)
        
        // MARK: - WalletsViewModel
        register { WalletsViewModel() }
            .implements(WalletsRepository.self)
            .implements(WLNotificationsRepository.self)
            .scope(.session)
        
        // MARK: - OrcaSwap
        register { OrcaSwap(
            apiClient: OrcaSwap.APIClient(
                network: Defaults.apiEndPoint.network.cluster
            ),
            solanaClient: resolve(),
            accountProvider: resolve(),
            notificationHandler: resolve())
        }
            .implements(OrcaSwapType.self)
            .scope(.session)
        
        // MARK: - RenVM
        register { RenVM.RpcClient(network: Defaults.apiEndPoint.network == .mainnetBeta ? .mainnet: .testnet) }
            .implements(RenVMRpcClientType.self)
            .scope(.session)
        
        register {
            RenVM.LockAndMint.Service(
                rpcClient: resolve(),
                solanaClient: resolve(),
                account: resolve(SolanaSDK.self).accountStorage.account!,
                sessionStorage: RenVM.LockAndMint.SessionStorage(),
                transactionHandler: resolve()
            )
        }
            .implements(RenVMLockAndMintServiceType.self)
            .scope(.session)
        
        register {
            RenVM.BurnAndRelease.Service(
                rpcClient: resolve(),
                solanaClient: resolve(),
                account: resolve(SolanaSDK.self).accountStorage.account!,
                transactionStorage: RenVM.BurnAndRelease.TransactionStorage(),
                transactionHandler: resolve()
            )
        }
            .implements(RenVMBurnAndReleaseServiceType.self)
            .scope(.session)
        
        // MARK: - ProcessingTransactionsManager
        register { ProcessingTransactionsManager() }
            .implements(ProcessingTransactionsRepository.self)
            .scope(.session)
        
        // MARK: - Others
        register { SessionBannersAvailabilityState() }
            .scope(.session)
        
        register { PersistentBannersAvailabilityState() }
        register {
            ReserveUsernameBannerAvailabilityRepository(
                sessionBannersAvailabilityState: resolve(SessionBannersAvailabilityState.self),
                persistentBannersAvailabilityState: resolve(PersistentBannersAvailabilityState.self),
                nameStorage: resolve()
            )
        }
            .implements(ReserveUsernameBannerAvailabilityRepositoryType.self)
            .scope(.unique)
        register { BannersManager(usernameBannerRepository: resolve()) }
            .implements(BannersManagerType.self)
            .scope(.unique)
        register { BannerKindTransformer() }
            .implements(BannerKindTransformerType.self)
            .scope(.unique)
        
        register { DAppChannel() }
            .implements(DAppChannelType.self)
        
        // MARK: - Moonpay
        register{Moonpay.MoonpayServiceImpl(api: Moonpay.API.fromEnvironment())}
            .implements(MoonpayService.self)
            .scope(.shared)
    
        // MARK: - BuyProvider
        register{BuyProviders.MoonpayFactory()}
            .implements(BuyProviderFactory.self)
            .scope(.application)
        
        // MARK: - AppEventHandler
        register {AppEventHandler()}
            .implements(AppEventHandlerType.self)
            .implements(DeviceOwnerAuthenticationHandler.self)
            .implements(ChangeNetworkResponder.self)
            .implements(ChangeLanguageResponder.self)
            .implements(LogoutResponder.self)
            .implements(CreateOrRestoreWalletHandler.self)
            .implements(OnboardingHandler.self)
            .scope(.application)
        
        // MARK: - AuthenticationHandler
        register {AuthenticationHandler()}
            .implements(AuthenticationHandlerType.self)
            .scope(.session)
        
        register{ReceiveToken.QrCodeImageRenderImpl()}
            .implements(QrCodeImageRender.self)
            .scope(.application)
        
        // MARK: - RentBTC
        register {
            RentBtcServiceImpl(
                solanaSDK: resolve(),
                feeRelayerApi: resolve(),
                accountStorage: resolve(),
                walletRepository: resolve(),
                orcaSwap: resolve()
            )
        }
            .implements(RentBTC.Service.self)
            .scope(.session)
    }
}

extension ResolverScope {
    static let session = ResolverScopeCache()
}
