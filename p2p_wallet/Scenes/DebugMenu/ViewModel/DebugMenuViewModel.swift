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

final class DebugMenuViewModel: BaseViewModel {
    @Published var networkLoggerVisible = isShown {
        didSet {
            updateNetworkLoggerState()
        }
    }

    @Published var features: [FeatureItem]
    @Published var solanaEndpoints: [APIEndPoint] = [
        .init(address: "https://api.mainnet-beta.solana.com", network: .mainnetBeta),
        .init(address: "https://api.testnet.solana.com", network: .testnet),
        .init(address: "https://api.devnet.solana.com", network: .devnet),
    ]
    @Published var selectedEndpoint = Defaults.apiEndPoint

    override init() {
        features = Menu.allCases
            .map {
                FeatureItem(
                    title: $0.title,
                    feature: $0.feature,
                    isOn: available($0.feature)
                )
            }
        super.init()

        $selectedEndpoint.sink { endpoint in
            Defaults.apiEndPoint = endpoint
        }.store(in: &subscriptions)
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
        case newSettings

        case mockedApiGateway
        case mockedTKeyFacade
        case simulatedSocialError

        var title: String {
            switch self {
            case .newSettings: return "New Settings"
            case .mockedApiGateway: return "[Onboarding] API Gateway Mock"
            case .mockedTKeyFacade: return "[Onboarding] TKeyFacade Mock"
            case .simulatedSocialError: return "[Onboarding] Simulated Social Error"
            }
        }

        var feature: Feature {
            switch self {
            case .newSettings: return .settingsFeature
            case .mockedApiGateway: return .mockedApiGateway
            case .mockedTKeyFacade: return .mockedTKeyFacade
            case .simulatedSocialError: return .simulatedSocialError
            }
        }
    }
}

extension APIEndPoint: Identifiable {
    public var id: String { address }
}
