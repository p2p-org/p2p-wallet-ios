//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import SolanaSwift
import FeeRelayerSwift

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
            .implements(SendTokenAPIClient.self)
            .implements(FeeAPIClient.self)
            .implements(OrcaSwapSolanaClient.self)
            .implements(OrcaSwapAccountProvider.self)
            .implements(OrcaSwapSignatureConfirmationHandler.self)
            .implements(ProcessTransactionAPIClient.self)
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
        
        register { FeeRelayer() }
            .implements(FeeRelayerType.self)
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
        
        // MARK: - Root
        register {Root.ViewModel()}
            .implements(RootViewModelType.self)
            .implements(ChangeNetworkResponder.self)
            .implements(ChangeLanguageResponder.self)
            .implements(LogoutResponder.self)
            .implements(CreateOrRestoreWalletHandler.self)
            .implements(OnboardingHandler.self)
            .implements(DeviceOwnerAuthenticationHandler.self)
            .scope(.shared)
        
        // MARK: - CreateOrRestoreWallet
        register {CreateOrRestoreWallet.ViewModel()}
            .implements(CreateOrRestoreWalletViewModelType.self)
            .scope(.shared)
        
        // CreateWallet
        register {CreateWallet.ViewModel()}
            .implements(CreateWalletViewModelType.self)
            .scope(.shared)
        
        // CreateSecurityKeys
        register {CreateSecurityKeys.ViewModel()}
            .implements(CreateSecurityKeysViewModelType.self)
            .scope(.shared)
        
        // RestoreWallet
        register {RestoreWallet.ViewModel()}
            .implements(RestoreWalletViewModelType.self)
            .implements(AccountRestorationHandler.self)
            .scope(.shared)
        
        // DerivableAccounts
        register { _, args in
            DerivableAccounts.ViewModel(phrases: args())
        }
            .implements(DerivableAccountsListViewModelType.self)
            .scope(.shared)
        
        // MARK: - Onboarding
        register {Onboarding.ViewModel()}
            .implements(OnboardingViewModelType.self)
            .scope(.shared)
        
        // MARK: - Authentication
        register {Authentication.ViewModel()}
            .implements(AuthenticationViewModelType.self)
            .scope(.shared)
        
        // MARK: - ResetPinCodeWithSeedPhrases
        register {ResetPinCodeWithSeedPhrases.ViewModel()}
            .implements(ResetPinCodeWithSeedPhrasesViewModelType.self)
            .scope(.shared)
        
        // MARK: - Main
        register {MainViewModel()}
            .implements(MainViewModelType.self)
            .implements(AuthenticationHandler.self)
            .scope(.shared)
        
        // MARK: - Home
        register { Home.ViewModel() }
            .implements(HomeViewModelType.self)
            .scope(.shared)
        
        // MARK: - WalletDetail
        register { WalletDetail.ViewModel() }
            .implements(WalletDetailViewModelType.self)
            .scope(.shared)

        // MARK: - EnterSeedPhrase
        register { EnterSeed.ViewModel() }
            .implements(EnterSeedViewModelType.self)
            .scope(.unique)
        register { EnterSeedInfo.ViewModel() }
            .implements(EnterSeedInfoViewModelType.self)
            .scope(.unique)
        
        // MARK: - Moonpay
        register{Moonpay.MoonpayServiceImpl(api: Moonpay.API.fromEnvironment())}
            .implements(MoonpayService.self)
            .scope(.shared)
    
        // MARK: - BuyProvider
        register{BuyProviders.MoonpayFactory()}
            .implements(BuyProviderFactory.self)
            .scope(.application)
        
        // MARK: - TransactionInfo
        register { TransactionInfoViewModel() }
            .scope(.shared)
        
        // MARK: - BuyRoot
        register { BuyRoot.ViewModel() }
            .implements(BuyViewModelType.self)
            .scope(.shared)
        
        register { SolanaBuyToken.SceneModel() }
            .implements(SolanaBuyTokenSceneModel.self)
            .scope(.shared)
        
        // MARK: - Receive
        register { ReceiveToken.SceneModel() }
            .implements(ReceiveSceneModel.self)
            .scope(.shared)
        
        // MARK: - Send
        register { SendToken.ViewModel() }
            .implements(SendTokenViewModelType.self)
            .scope(.shared)
        
        // MARK: - OrcaSwap
        register { OrcaSwapV2.ViewModel() }
            .implements(OrcaSwapV2ViewModelType.self)
            .scope(.shared)
        
        // MARK: - Choose wallet
        register { ChooseWallet.ViewModel() }
            .scope(.shared)
        
        // MARK: - ProcessTransaction
        register { ProcessTransaction.ViewModel() }
            .implements(ProcessTransactionViewModelType.self)
            .scope(.shared)
        
        // MARK: - Token settings
        register { TokenSettingsViewModel() }
            .scope(.shared)
    }
}

extension ResolverScope {
    static let session = ResolverScopeCache()
}
