//
//  FeatureFlag.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

public struct FeatureFlag: Equatable, Codable {
    public let feature: Feature
    public let isEnabled: Bool

    public init(
        feature: Feature,
        enabled: Bool
    ) {
        self.feature = feature
        isEnabled = enabled
    }
}

extension FeatureFlag: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(feature.rawValue): \(isEnabled)"
    }
}
