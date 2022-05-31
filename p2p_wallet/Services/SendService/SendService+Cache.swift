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

    enum Error: String, Swift.Error, LocalizedError {
        case invalidSourceWallet = "Source wallet is not valid"
        case sendToYourself = "You can not send tokens to yourself"
        case unknown = "Unknown error"

        var errorDescription: String? {
            // swiftlint:disable swiftgen_strings
            NSLocalizedString(rawValue, comment: "")
            // swiftlint:enable swiftgen_strings
        }
    }
}
