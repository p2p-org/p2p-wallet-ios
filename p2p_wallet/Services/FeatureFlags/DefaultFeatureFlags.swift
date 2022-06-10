//
//  DefaultFeatureFlags.swift
//  Dbomsb
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

func setupDefaultFlags() {
    defaultFlags = StaticFlagsFetcher(
        featureFlags: PlistFiles.defaultFf
            .split(separator: ",")
            .map(String.init)
            .compactMap(Feature.init(rawValue:))
            .map { FeatureFlag(feature: $0, enabled: true) }
    )
}
