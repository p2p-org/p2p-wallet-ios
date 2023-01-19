//
//  FeatureFlagProvider+Rx.swift
//  Alamofire
//
//  Created by Babich Ivan on 10.06.2022.
//

import Foundation
import RxSwift

public extension Reactive where Base: FeatureFlagProvider {
    func fetchFeatureFlags(mainFetcher: FetchesFeatureFlags,
                           fallbackFetcher: FetchesFeatureFlags? = nil) -> Single<[FeatureFlag]>
    {
        .create { [weak base] single in
            base?.fetchFeatureFlags(mainFetcher: mainFetcher, fallbackFetcher: fallbackFetcher) {
                single(.success($0))
            }
            return Disposables.create()
        }
    }
}
