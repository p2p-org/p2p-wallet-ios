//
//  SwapProviderType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/08/2021.
//

import Foundation
import RxSwift

protocol SwapProviderType {
    func loadPrice(fromMint: String, toMint: String) -> Single<Double>
}
