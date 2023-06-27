//
//  Available.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

/// Checks feature availability
/// Example
/// ```
/// import FeatureFlags
/// ...
/// // somewhere in applicationDidFinishLaunching
/// FeatureFlagProvider.shared.fetchFeatureFlags(mainFetcher: .firebase, fallbackFetcher: .local) {
///     hideSplashAndContinue()
/// }
/// ...
/// // in your module
/// if available(.myNewSuperFeature) {
///     showMyNewSuperFeature()
/// } else {
///     showOldFeature()
/// }
/// ```
/// - Parameters:
///   - feature: feature to be checked
///   - provider: provder that holds available features list
public func available(_ feature: Feature, provider: FeatureFlagProvider = .shared) -> Bool {
    provider.isEnabled(feature)
}
