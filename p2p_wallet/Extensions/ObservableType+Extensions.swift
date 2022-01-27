//
//  ObservableType+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift

extension Timer {
    static func observable(
        seconds: Int,
        scheduler: SchedulerType = MainScheduler.instance
    ) -> Observable<Void> {
        Observable<Int>.timer(.seconds(0), period: .seconds(seconds), scheduler: scheduler)
            .map {_ in ()}
    }
}
