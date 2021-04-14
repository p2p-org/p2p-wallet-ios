//
//  CreateTokenHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/03/2021.
//

import Foundation
import RxSwift

protocol CreateTokenHandler {
    func getCreatingTokenAccountFee() -> Single<UInt64>
    func createTokenAccount(mintAddress: String, isSimulation: Bool) -> Single<(signature: String, newPubkey: String)>
}

extension SolanaSDK: CreateTokenHandler {}
