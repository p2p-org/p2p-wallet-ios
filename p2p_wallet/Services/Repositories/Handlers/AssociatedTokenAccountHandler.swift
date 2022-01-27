//
//  AssociatedTokenAccountHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2021.
//

import Foundation
import RxSwift

protocol AssociatedTokenAccountHandler {
    func createAssociatedTokenAccount(
        tokenMint: SolanaSDK.PublicKey,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
}

extension SolanaSDK: AssociatedTokenAccountHandler {    
    func createAssociatedTokenAccount(tokenMint: PublicKey, isSimulation: Bool) -> Single<TransactionID> {
        guard let account = accountStorage.account
        else {return .error(SolanaSDK.Error.unauthorized)}
        
        return createAssociatedTokenAccount(
            for: account.publicKey,
            tokenMint: tokenMint,
            isSimulation: isSimulation
        )
    }
}
