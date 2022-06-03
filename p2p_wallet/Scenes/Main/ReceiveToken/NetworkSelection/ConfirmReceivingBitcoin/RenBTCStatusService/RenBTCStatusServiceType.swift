//
//  RenBTCStatusService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation
import RxSwift
import SolanaSwift

/// The `RenBTCServiceType` helps to prepare with renBTC service.
///
/// The protocol contains creating account, calculate fee for creation and check availability of balance.
protocol RenBTCStatusServiceType {
    func load() async throws

    /// Checks the associated account has been created.
    ///
    /// RenBTC works, when account has been created.
    ///
    /// - Returns: the status
    func hasRenBTCAccountBeenCreated() -> Bool

    /// Checks the associated account is creatable.
    ///
    /// This methods calculate all factors, that may affect to fee like account creation fee, trx fee and fee relayer fee.
    ///
    /// - Returns: true if account is creatable or false. The false happens when wallet balance is not enough for creating.
    func getPayableWallets() async throws -> [Wallet]

    /// Creates a associated account.
    ///
    /// - Parameters:
    ///   - payingFeeAddress: the address that will pay a fee.
    ///   - payingFeeMintAddress: the mint address that will pay a fee.
    /// - Returns: transaction signature
    func createAccount(
        payingFeeAddress: String,
        payingFeeMintAddress: String
    ) async throws

    /// Get amount of feed needed to create renBTC account.
    ///
    /// The amount will be in spl currency.
    ///
    /// - Parameter payingFeeMintAddress: the mint address that will be used as fee paying.
    /// - Returns: the amount of fee
    func getCreationFee(
        payingFeeMintAddress: String
    ) async throws -> Lamports
}
