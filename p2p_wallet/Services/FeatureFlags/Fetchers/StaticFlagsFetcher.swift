//
//  StaticFlagsFetcher.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

struct StaticFlagsFetcher: FetchesFeatureFlags, ExpressibleByDictionaryLiteral {
    private let featureFlags: [FeatureFlag]

    init(featureFlags: [FeatureFlag]) {
        self.featureFlags = featureFlags
    }

    init(dictionaryLiteral elements: (Feature, Bool)...) {
        featureFlags = .init(
            elements.map {
                FeatureFlag(
                    feature: $0,
                    enabled: $1
                )
            }
        )
    }

    func fetchFeatureFlags(_ completion: @escaping ([FeatureFlag]) -> Void) {
        completion(featureFlags)
    }
}
