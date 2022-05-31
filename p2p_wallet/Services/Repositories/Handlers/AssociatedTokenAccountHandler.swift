//
//  AssociatedTokenAccountHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2021.
//

import Foundation
import RxSwift
import SolanaSwift

protocol AssociatedTokenAccountHandler {
    func hasAssociatedTokenAccountBeenCreated(
        tokenMint: PublicKey
    ) -> Single<Bool>

    func createAssociatedTokenAccount(
        tokenMint: PublicKey,
        isSimulation: Bool
    ) -> Single<TransactionID>
}

extension SolanaSDK: AssociatedTokenAccountHandler {
    func hasAssociatedTokenAccountBeenCreated(tokenMint: PublicKey) -> Single<Bool> {
        hasAssociatedTokenAccountBeenCreated(owner: nil, tokenMint: tokenMint)
    }

    func createAssociatedTokenAccount(tokenMint: PublicKey, isSimulation: Bool) -> Single<TransactionID> {
        guard let account = accountStorage.account
        else { return .error(SolanaError.unauthorized) }

        return createAssociatedTokenAccount(
            for: account.publicKey,
            tokenMint: tokenMint,
            isSimulation: isSimulation
        )
    }
}
