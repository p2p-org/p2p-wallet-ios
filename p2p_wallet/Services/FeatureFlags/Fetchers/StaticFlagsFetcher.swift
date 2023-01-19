//
//  StaticFlagsFetcher.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

public struct StaticFlagsFetcher: FetchesFeatureFlags, ExpressibleByDictionaryLiteral {
    private let featureFlags: [FeatureFlag]

    public init(featureFlags: [FeatureFlag]) {
        self.featureFlags = featureFlags
    }

    public init(dictionaryLiteral elements: (Feature, Bool)...) {
        featureFlags = .init(
            elements.map {
                FeatureFlag(
                    feature: $0,
                    enabled: $1
                )
            }
        )
    }

    public func fetchFeatureFlags(_ completion: @escaping ([FeatureFlag]) -> Void) {
        completion(featureFlags)
    }
}
