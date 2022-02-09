//
// Created by Giang Long Tran on 07.02.2022.
//

import Foundation
import RxSwift
import FeeRelayerSwift

//class RentBtcServiceImpl: RentBTC.Service {
//    private let solanaSDK: SolanaSDK
//    private let feeRelayer: FeeRelayer.Relay
//
//    init(solanaSDK: SolanaSDK) { self.solanaSDK = solanaSDK }
//
//    func hasAssociatedTokenAccountBeenCreated() -> Single<Bool> {
//        solanaSDK.hasAssociatedTokenAccountBeenCreated(tokenMint: .renBTCMint)
//    }
//
//    func createAssociatedTokenAccount() -> Single<SolanaSDK.TransactionID> {
//        guard let account = solanaSDK.accountStorage.account else { return .error(SolanaSDK.Error.unauthorized) }
//        solanaSDK.createAssociatedTokenAccount(
//            for: account.publicKey,
//            tokenMint: .renBTCMint,
//            payer: nil,
//            isSimulation: false
//        )
//
//    return  .just("")
//    }
//
//}
