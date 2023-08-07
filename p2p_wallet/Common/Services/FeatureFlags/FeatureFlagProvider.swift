import Foundation

final class FeatureFlagProvider {
    static let shared = FeatureFlagProvider()

    var featureFlags: [FeatureFlag] {
        didSet {
            UserDefaults.standard.storagedFeatures = featureFlags
        }
    }

    private init() {
        featureFlags = UserDefaults.standard.storagedFeatures
    }

    func fetchFeatureFlags(
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

    func isEnabled(_ feature: Feature) -> Bool {
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
