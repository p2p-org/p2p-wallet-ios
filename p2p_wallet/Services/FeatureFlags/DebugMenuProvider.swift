//
//  DebugMenuProvider.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import Foundation

private protocol DebugMenuFeaturesStorage: AnyObject {
    var debugMenuFeatures: [FeatureFlag] { get set }
}

public final class DebugMenuFeaturesProvider: FetchesFeatureFlags {
    public static let shared = DebugMenuFeaturesProvider()

    private var featureFlags = [FeatureFlag]()
    private let storage: DebugMenuFeaturesStorage

    private init(storage: DebugMenuFeaturesStorage = UserDefaults.standard) {
        self.storage = storage
    }

    public func fetchFeatureFlags(_ completion: @escaping ([FeatureFlag]) -> Void) {
        featureFlags = storage.debugMenuFeatures
        completion(featureFlags)
    }

    public func updateFlag(for feature: Feature, with value: Bool) {
        featureFlags = featureFlags.filter { $0.feature != feature }
        featureFlags.append(FeatureFlag(feature: feature, enabled: value))
        storage.debugMenuFeatures = featureFlags
    }
}

extension UserDefaults: DebugMenuFeaturesStorage {
    static let featureFlagsKey = "feature_flags"

    var debugMenuFeatures: [FeatureFlag] {
        get {
            guard
                let data = data(forKey: Self.featureFlagsKey),
                let feautreFlags = try? PropertyListDecoder().decode([FeatureFlag].self, from: data)
            else { return [] }
            return feautreFlags
        }
        set {
            guard let data = try? PropertyListEncoder().encode(newValue) else {
                assertionFailure("Failed to set feature flags to UserDefaults")
                return
            }
            set(data, forKey: Self.featureFlagsKey)
        }
    }
}
