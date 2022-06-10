//
//  MergingFlagsFetcher.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

/// Merges flags from primary and secondary fetchers using following logic
/// secondary flag state | primary flag state | result flag state
///        nil           |        nil         |        nil
///        nil           |         0          |         0
///        nil           |         1          |         1
///         0            |        nil         |         0
///         0            |         0          |         0
///         0            |         1          |         1
///         1            |        nil         |         1
///         1            |         0          |         0
///         1            |         1          |         1
public final class MergingFlagsFetcher: FetchesFeatureFlags {
    private let primaryFetcher: FetchesFeatureFlags
    private let secondaryFetcher: FetchesFeatureFlags

    public init(
        primaryFetcher: FetchesFeatureFlags,
        secondaryFetcher: FetchesFeatureFlags
    ) {
        self.primaryFetcher = primaryFetcher
        self.secondaryFetcher = secondaryFetcher
    }

    public func fetchFeatureFlags(_ completion: @escaping ([FeatureFlag]) -> Void) {
        var primaryFlags = [FeatureFlag]()
        var secondaryFlags = [FeatureFlag]()
        let group = DispatchGroup()
        group.enter()
        primaryFetcher.fetchFeatureFlags {
            primaryFlags = $0
            group.leave()
        }
        group.enter()
        secondaryFetcher.fetchFeatureFlags {
            secondaryFlags = $0
            group.leave()
        }
        group.notify(queue: .main) {
            let primaryFeatures = Set(primaryFlags.map(\.feature))
            let secondaryFeatures = Set(secondaryFlags.map(\.feature))
            let merged = primaryFeatures.union(secondaryFeatures)
                .map { feature in
                    (
                        primaryFlags.first(where: { $0.feature == feature }),
                        secondaryFlags.first(where: { $0.feature == feature })
                    )
                }.compactMap { primary, secondary -> FeatureFlag? in
                    switch (primary, secondary) {
                    case let (primary?, secondary?):
                        let merged = (!secondary.isEnabled || primary.isEnabled) &&
                            (secondary.isEnabled || primary.isEnabled)
                        return FeatureFlag(feature: secondary.feature, enabled: merged)
                    case let (primary?, nil):
                        return primary
                    case let (nil, secondary?):
                        return secondary
                    case (nil, nil):
                        return nil
                    }
                }
            completion(merged)
        }
    }
}
