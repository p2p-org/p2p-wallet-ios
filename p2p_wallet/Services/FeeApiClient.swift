//
//  FeeApiClient.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import RxSwift

protocol FeeAPIClient {
    func getLamportsPerSignature() -> Single<SolanaSDK.Lamports>
    func getCreatingTokenAccountFee() -> Single<UInt64>
}

extension SolanaSDK: FeeAPIClient {
    func getLamportsPerSignature() -> Single<Lamports> {
        getFees().map {$0.feeCalculator?.lamportsPerSignature}.map {$0 ?? 0}
    }
}
