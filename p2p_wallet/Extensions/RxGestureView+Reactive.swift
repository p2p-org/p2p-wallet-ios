//
//  RxGestureView+Reactive.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/05/2022.
//

import Foundation
import RxGesture
import RxSwift

extension Reactive where Base: RxGestureView {
    var onTap: Observable<Void> {
        tapGesture()
            .when(.recognized)
            .mapToVoid()
    }
}
