import Foundation
import Resolver
import NameService
import SolanaSwift
import Web3

extension Resolver {
    /// Graph scope: Recreate and reuse dependencies
    @MainActor static func registerForGraphScope() {
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
            tokenListParser: .init(
                url: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/src/tokens/solana.tokenlist.json"
            ),
            cache: resolve()
        ) }
        .implements(SolanaTokensRepository.self)
        .scope(.application)
        
        // QrCodeImageRender
        register { QrCodeImageRenderImpl() }
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
        
        register { Web3(rpcURL: String.secretConfig("ETH_RPC")!) }
    }
}
