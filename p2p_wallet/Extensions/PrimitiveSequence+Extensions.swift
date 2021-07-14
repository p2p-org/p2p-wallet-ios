//
//  PrimitiveSequence+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/07/2021.
//

import Foundation
import RxSwift
extension PrimitiveSequence {
    func retry(maxAttempts: Int, delayInSeconds seconds: Int) -> PrimitiveSequence<Trait, Element> {
        return self.retry(when: { errors in
            return errors.enumerated().flatMap { (index, error) -> Observable<Int64> in
                if index <= maxAttempts {
                    return Observable<Int64>.timer(.seconds(seconds), scheduler: MainScheduler.instance)
                } else {
                    return Observable.error(error)
                }
            }
        })
    }
}
