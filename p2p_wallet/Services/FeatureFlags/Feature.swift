//
//  Feature.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

public struct Feature: RawRepresentable, Hashable, Codable {
    private let name: String

    public var rawValue: String {
        name
    }

    public init(rawValue: String) {
        name = rawValue
    }
}
