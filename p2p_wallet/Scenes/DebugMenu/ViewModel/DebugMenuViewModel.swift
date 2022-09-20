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
        features = []
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
