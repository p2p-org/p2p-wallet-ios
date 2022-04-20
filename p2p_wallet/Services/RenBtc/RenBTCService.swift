//
// Created by Giang Long Tran on 07.02.2022.
//

import Foundation
import RxSwift
import SolanaSwift

struct RentBTC {
    typealias Service = RenBTCServiceType
}

/// The `RenBTCServiceType` helps to prepare with renBTC service.
///
/// The protocol contains creating account, calculate fee for creation and check availability of balance.
protocol RenBTCServiceType {
    /// Checks the associated account has been created.
    ///
    /// RenBTC works, when account has been created.
    ///
    /// - Returns: the status
    func hasAssociatedTokenAccountBeenCreated() -> Bool

    /// Checks the associated account is creatable.
    ///
    /// This methods calculate all factors, that may affect to fee like account creation fee, trx fee and fee relayer fee.
    ///
    /// - Returns: true if account is creatable or false. The false happens when wallet balance is not enough for creating.
    func isAssociatedAccountCreatable() async throws -> Bool

    /// Creates a associated account.
    ///
    /// - Parameters:
    ///   - payingFeeAddress: the address that will pay a fee.
    ///   - payingFeeMintAddress: the mint address that will pay a fee.
    /// - Returns: transaction signature
    func createAccount(
        payingFeeAddress: String,
        payingFeeMintAddress: String
    ) async throws -> SolanaSDK.TransactionID

    /// Get amount of feed needed to create renBTC account.
    ///
    /// The amount will be in spl currency.
    ///
    /// - Parameter payingFeeMintAddress: the mint address that will be used as fee paying.
    /// - Returns: the amount of fee
    func getCreationFee(payingFeeMintAddress: String) async throws -> SolanaSDK.Lamports
}
