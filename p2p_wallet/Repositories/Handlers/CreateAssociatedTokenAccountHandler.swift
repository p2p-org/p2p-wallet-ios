//
//  CreateAssociatedTokenAccountHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2021.
//

import Foundation
import RxSwift

protocol CreateAssociatedTokenAccountHandler {
    func createAssociatedTokenAccount(
        for owner: SolanaSDK.PublicKey,
        tokenMint: SolanaSDK.PublicKey,
        payer: SolanaSDK.Account?,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
}

extension SolanaSDK: CreateAssociatedTokenAccountHandler {}
