//
//  ObservableType+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift

extension ObservableType {
    func withPrevious() -> Observable<(Element?, Element)> {
        scan([], accumulator: { previous, current in
            Array(previous + [current]).suffix(2)
        })
        .map { arr -> (previous: Element?, current: Element) in
            (arr.count > 1 ? arr.first : nil, arr.last!)
        }
    }
}

extension Timer {
    static func observable(
        seconds: Int,
        scheduler: SchedulerType = MainScheduler.instance
    ) -> Observable<Void> {
        Observable<Int>.timer(.seconds(0), period: .seconds(seconds), scheduler: scheduler)
            .map { _ in () }
    }
}
