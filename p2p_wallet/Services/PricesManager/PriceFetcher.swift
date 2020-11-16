//
//  PriceFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

struct Price: Hashable {
    let from: String
    var to: String = "USDT"
    var value: Double?
}

protocol PricesFetcher {
    typealias Pair = (from: String, to: String)
    var pairs: [Pair] {get set}
    var prices: BehaviorRelay<[Price]> {get}
    func fetchAll()
    var disposeBag: DisposeBag {get}
}
