//
//  SendServiceType.swift
//  p2p_wallet
//
//  Created by chungtran on 31/03/2022.
//

import FeeRelayerSwift
import Foundation
import RxSwift
import SolanaSwift

protocol SendServiceType {
    func load() -> Completable
    func checkAccountValidation(account: String) -> Single<Bool>
    func isTestNet() -> Bool

    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendToken.Network,
        payingTokenMint: String?
    ) -> Single<FeeAmount?>

    func getFeesInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeWallet: Wallet
    ) -> Single<FeeAmount?>

    // TODO: hide direct usage of ``UsageStatus``
    func getFreeTransactionFeeLimit(
    ) -> Single<UsageStatus>

    func getAvailableWalletsToPayFee(
        feeInSOL: FeeAmount
    ) -> Single<[Wallet]>

    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendToken.Network,
        payingFeeWallet: Wallet?
    ) -> Single<String>
}
