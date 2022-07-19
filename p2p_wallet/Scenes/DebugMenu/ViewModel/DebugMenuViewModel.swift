//
//  DebugMenuViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import Combine
import FirebaseRemoteConfig
import Foundation
import SwiftyUserDefaults

final class DebugMenuViewModel: ObservableObject {
    @Published var networkLoggerVisible = isShown {
        didSet {
            updateNetworkLoggerState()
        }
    }

    @Published var features: [FeatureItem]
    @Published var urlToggles: [UrlItem]

    init() {
        features = Menu.allCases.map {
            FeatureItem(
                title: $0.title,
                feature: $0.feature,
                isOn: available($0.feature)
            )
        }
        urlToggles = UrlMenu.allCases.map {
            UrlItem(
                title: $0.title,
                configParts: $0.configParts,
                type: $0,
                currentConfigPart: $0.currentConfigPath
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

    func setCurrentConfigPath(_ configPath: String, for urlItem: UrlItem) {
        switch urlItem.type {
        case .feeRelayer:
            Defaults.feeRelayerConfigPath = configPath
        case .push:
            Defaults.notificationServiceConfigPath = configPath
        }
    }

    private func updateNetworkLoggerState() {
        #if !RELEASE
            showDebugger(networkLoggerVisible)
        #endif
    }
}

// MARK: - Model

extension DebugMenuViewModel {
    struct FeatureItem {
        let title: String
        let feature: Feature
        var isOn: Bool
    }

    struct UrlItem {
        let title: String
        let configParts: [String]
        fileprivate let type: UrlMenu
        var currentConfigPart: String
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

    enum UrlMenu: Int, CaseIterable {
        case feeRelayer
        case push

        var title: String {
            switch self {
            case .feeRelayer:
                return "Fee Relayer"
            case .push:
                return "Push Notifications"
            }
        }

        var configParts: [String] {
            switch self {
            case .feeRelayer:
                return ["FEE_RELAYER_STAGING_ENDPOINT", "FEE_RELAYER_ENDPOINT"]
            case .push:
                return ["NOTIFICATION_SERVICE_ENDPOINT", "NOTIFICATION_SERVICE_ENDPOINT_RELEASE"]
            }
        }

        var currentConfigPath: String {
            switch self {
            case .feeRelayer:
                return Defaults.feeRelayerConfigPath
            case .push:
                return Defaults.notificationServiceConfigPath
            }
        }
    }
}
