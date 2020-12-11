//
//  PriceFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxSwift
import RxCocoa

protocol PricesFetcher {
    func getCurrentPrice(from: String, to: String) -> Single<Price>
}
