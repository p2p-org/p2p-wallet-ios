//
//  DebugMenuViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import Combine
import FirebaseRemoteConfig
import SwiftyUserDefaults

final class DebugMenuViewModel: ObservableObject {
    @Published var networkLoggerVisible = isShown {
        didSet {
            updateNetworkLoggerState()
        }
    }

    @Published var features: [FeatureItem]

    init() {
        features = Menu.allCases
            .map {
                FeatureItem(
                    title: $0.title,
                    feature: $0.feature,
                    isOn: available($0.feature)
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

    private func updateNetworkLoggerState() {
        showDebugger(networkLoggerVisible)
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
        case sslPinning

        var title: String {
            switch self {
            case .sslPinning:
                return "SSL Pinning"
            }
        }

        var feature: Feature {
            switch self {
            case .sslPinning:
                return .sslPinning
            }
        }
    }
}
