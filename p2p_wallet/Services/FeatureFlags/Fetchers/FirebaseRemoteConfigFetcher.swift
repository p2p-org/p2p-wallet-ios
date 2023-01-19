//
//  FirebaseRemoteConfigFetcher.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

import FirebaseRemoteConfig
import Foundation

extension RemoteConfig: FetchesFeatureFlags {
    public func fetchFeatureFlags(_ completion: @escaping ([FeatureFlag]) -> Void) {
        fetchAndActivate { [weak self] status, _ in
            guard
                let self = self,
                status != .error
            else { return completion([]) }

            completion(
                .init(
                    self.allKeys(from: .remote).map {
                        FeatureFlag(
                            feature: Feature(rawValue: $0),
                            enabled: self.configValue(forKey: $0).boolValue
                        )
                    }
                )
            )
        }
    }
}
