//
//  FeatureFlagProvider.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation
import RxSwift

public final class FeatureFlagProvider: ReactiveCompatible {
    public static let shared = FeatureFlagProvider()

    var featureFlags: [FeatureFlag] = []

    init() {}

    public func fetchFeatureFlags(
        mainFetcher: FetchesFeatureFlags,
        fallbackFetcher: FetchesFeatureFlags? = nil,
        completion: (([FeatureFlag]) -> Void)? = nil
    ) {
        fetchFeatureFlags(using: mainFetcher) { [weak self] flags in
            guard flags.isEmpty, let fallbackFetcher = fallbackFetcher else {
                completion?(flags)
                return
            }
            self?.fetchFeatureFlags(using: fallbackFetcher) { flags in
                completion?(flags)
            }
        }
    }

    public func isEnabled(_ feature: Feature) -> Bool {
        featureFlags.first(where: { $0.feature == feature })?.isEnabled ?? false
    }
}

private extension FeatureFlagProvider {
    func fetchFeatureFlags(using fetcher: FetchesFeatureFlags, completion: @escaping ([FeatureFlag]) -> Void) {
        fetcher.fetchFeatureFlags { [weak self] flags in
            self?.featureFlags = flags
            completion(flags)
        }
    }
}
