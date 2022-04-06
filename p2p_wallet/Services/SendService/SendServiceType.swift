//
//  SendServiceType.swift
//  p2p_wallet
//
//  Created by chungtran on 31/03/2022.
//

import FeeRelayerSwift
import Foundation
import RxSwift

protocol SendServiceType {
    func load() -> Completable
    func checkAccountValidation(account: String) -> Single<Bool>
    func isTestNet() -> Bool

    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendToken.Network,
        payingTokenMint: String?
    ) -> Single<SolanaSDK.FeeAmount?>
    func getFeesInPayingToken(
        feeInSOL: SolanaSDK.FeeAmount,
        payingFeeWallet: Wallet
    ) -> Single<SolanaSDK.FeeAmount?>

    func getFreeTransactionFeeLimit(
    ) -> Single<FeeRelayer.Relay.FreeTransactionFeeLimit>

    func getAvailableWalletsToPayFee(
        feeInSOL: SolanaSDK.FeeAmount
    ) -> Single<[Wallet]>

    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendToken.Network,
        payingFeeWallet: Wallet?
    ) -> Single<String>
}
