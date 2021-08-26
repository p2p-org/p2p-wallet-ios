//
//  SerumSwap+SwapProviderType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/08/2021.
//

import Foundation
import RxSwift

extension SerumSwap: SwapProviderType {
    func loadPrice(fromMint: String, toMint: String) -> Single<Double> {
        guard let fromMint = try? Self.PublicKey(string: fromMint),
              let toMint = try? Self.PublicKey(string: toMint)
        else {return .error(SolanaSDK.Error.unknown)}
        return loadFair(fromMint: fromMint, toMint: toMint)
    }
}
