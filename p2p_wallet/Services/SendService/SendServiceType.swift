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

protocol SendServiceType: AnyObject {
    func load() async throws
    func checkAccountValidation(account: String) async throws -> Bool
    func isTestNet() -> Bool

    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendToken.Network,
        payingTokenMint: String?
    ) async throws -> FeeAmount?

    func getFeesInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeWallet: Wallet
    ) async throws -> FeeAmount?

    // TODO: hide direct usage of ``UsageStatus``
    func getFreeTransactionFeeLimit() async throws -> UsageStatus

    func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet]

    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendToken.Network,
        payingFeeWallet: Wallet?
    ) async throws -> String
}
