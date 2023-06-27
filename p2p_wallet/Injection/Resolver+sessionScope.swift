import Foundation
import Resolver
import Wormhole
import Send
import FeeRelayerSwift
import KeyAppBusiness
import Sell
import OrcaSwapSwift
import Jupiter

extension Resolver {
    /// Session scope: Live when user is authenticated
    @MainActor static func registerForSessionScope() {
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
}
