//
//  DebugMenuViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import Combine
import FirebaseRemoteConfig
import SolanaSwift
import SwiftyUserDefaults

final class DebugMenuViewModel: BaseViewModel, ObservableObject {
    @Published var networkLoggerVisible = isShown {
        didSet {
            updateNetworkLoggerState()
        }
    }

    @Published var features: [FeatureItem]
    @Published var solanaEndpoints: [APIEndPoint]
    @Published var selectedEndpoint: APIEndPoint?
    @Published var feeRelayerEndpoints: [String]
    @Published var moonpayEnvironments: [DefaultsKeys.MoonpayEnvironment] = [.production, .sandbox]
    @Published var currentMoonpayEnvironment: DefaultsKeys.MoonpayEnvironment
    @Published var nameServiceEndpoints: [String]

    override init() {
        features = Menu.allCases
            .map {
                FeatureItem(
                    title: $0.title,
                    feature: $0.feature,
                    isOn: available($0.feature)
                )
            }

        let solanaEndpoints: [APIEndPoint] = [
            .init(address: "https://api.mainnet-beta.solana.com", network: .mainnetBeta),
            .init(address: "https://solana-api.projectserum.com", network: .mainnetBeta),
            .init(address: "https://p2p.rpcpool.com", network: .mainnetBeta),
            .init(address: "https://api.devnet.solana.com", network: .devnet),
        ]
        self.solanaEndpoints = solanaEndpoints
        selectedEndpoint = solanaEndpoints.first(where: { $0 == Defaults.apiEndPoint })

        feeRelayerEndpoints = [
            "https://\(String.secretConfig("FEE_RELAYER_STAGING_ENDPOINT")!)",
            "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)"
        ]
        
        nameServiceEndpoints = [
            "https://\(String.secretConfig("NAME_SERVICE_ENDPOINT_NEW")!)",
            "https://\(String.secretConfig("NAME_SERVICE_STAGING_ENDPOINT")!)"
        ]

        currentMoonpayEnvironment = Defaults.moonpayEnvironment

        super.init()

        $selectedEndpoint
            .sink { endpoint in
                guard let endpoint = endpoint else { return }
                Defaults.apiEndPoint = endpoint
            }
            .store(in: &subscriptions)
        $currentMoonpayEnvironment
            .sink { environment in
                Defaults.moonpayEnvironment = environment
            }
            .store(in: &subscriptions)
    }

    func setFeature(_ feature: Feature, isOn: Bool) {
        DebugMenuFeaturesProvider.shared.updateFlag(for: feature, with: isOn)
        FeatureFlagProvider.shared.fetchFeatureFlags(
            mainFetcher: MergingFlagsFetcher(
                primaryFetcher: DebugMenuFeaturesProvider.shared,
                secondaryFetcher: MergingFlagsFetcher(
                    primaryFetcher: RemoteConfig.remoteConfig(),
                    secondaryFetcher: defaultFlags
                )
            )
        )
    }

    private func updateNetworkLoggerState() {
        #if !RELEASE
            showDebugger(networkLoggerVisible)
        #endif
    }
}

extension DebugMenuViewModel {
    struct FeatureItem {
        let title: String
        let feature: Feature
        var isOn: Bool
    }
}

extension DebugMenuViewModel {
    enum Menu: Int, CaseIterable {
        case solanaNegativeStatus
        case onboardingUsernameEnabled
        case onboardingUsernameButtonSkipEnabled
        
        case investSolend
        case solendDisablePlaceholder

        case mockedApiGateway
        case mockedTKeyFacade
        case simulatedSocialError
        case sell

        var title: String {
            switch self {
            case .solanaNegativeStatus: return "Solana Negative Status"
            case .onboardingUsernameEnabled: return "Onboarding Username"
            case .onboardingUsernameButtonSkipEnabled: return "Onboarding Username Skip Button"
            case .mockedApiGateway: return "[Onboarding] API Gateway Mock"
            case .mockedTKeyFacade: return "[Onboarding] TKeyFacade Mock"
            case .simulatedSocialError: return "[Onboarding] Simulated Social Error"
            case .investSolend: return "Invest Solend"
            case .solendDisablePlaceholder: return "Solend Disable Placeholder"
            case .sell: return "Sell (Off Ramp)"
            }
        }

        var feature: Feature {
            switch self {
            case .solanaNegativeStatus: return .solanaNegativeStatus
            case .onboardingUsernameEnabled: return .onboardingUsernameEnabled
            case .onboardingUsernameButtonSkipEnabled: return .onboardingUsernameButtonSkipEnabled
            case .mockedApiGateway: return .mockedApiGateway
            case .mockedTKeyFacade: return .mockedTKeyFacade
            case .simulatedSocialError: return .simulatedSocialError
            case .investSolend: return .investSolendFeature
            case .solendDisablePlaceholder: return .solendDisablePlaceholder
            case .sell: return .sellScenarioEnabled
            }
        }
    }
}

extension APIEndPoint: Identifiable {
    public var id: String { address }
}
