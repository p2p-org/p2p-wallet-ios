//
//  FetchesFeatureFlags.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation

public protocol FetchesFeatureFlags {
    func fetchFeatureFlags(_ completion: @escaping ([FeatureFlag]) -> Void)
}
