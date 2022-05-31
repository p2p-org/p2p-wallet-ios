//
//  SendService+Cache.swift
//  p2p_wallet
//
//  Created by Chung Tran on 31/05/2022.
//

import Foundation
import OrcaSwapSwift

extension SendService {
    actor Cache {
        var feePayerPubkey: String?
        var poolsSPLToSOL = [String: [PoolsPair]]()

        func save(pubkey: String, poolsPairs: [PoolsPair]) {
            poolsSPLToSOL[pubkey] = poolsPairs
        }

        func saveFeePayerPubkey(_ pubkey: String) {
            feePayerPubkey = pubkey
        }
    }
}
