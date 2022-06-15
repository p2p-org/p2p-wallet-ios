//
//  DebugMenuViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import Combine
import FirebaseRemoteConfig

final class DebugMenuViewModel: ObservableObject {
    @Published var features: [FeatureItem]

    init() {
        features = Menu.allCases
            .map {
                FeatureItem(
                    title: $0.title,
                    feature: $0.feature,
                    isOn: $0.feature != nil ? available($0.feature!) : false
                )
            }
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
}

extension DebugMenuViewModel {
    struct FeatureItem {
        let title: String
        let feature: Feature?
        var isOn: Bool
    }
}

extension DebugMenuViewModel {
    enum Menu: Int, CaseIterable {
        case settingsNetworkValues
        case sslPinning

        var title: String {
            switch self {
            case .settingsNetworkValues:
                return "Network API domain"
            case .sslPinning:
                return "SSL Pinning"
            }
        }

        var feature: Feature? {
            switch self {
            case .settingsNetworkValues:
                return nil
            case .sslPinning:
                return .sslPinning
            }
        }
    }
}
