// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// The service that allows users to do gas-less transactions.
public protocol RelayService {
    var feeCalculator: RelayFeeCalculator { get }

    func relayTransaction(
        _ preparedTransaction: PreparedTransaction,
        config configuration: FeeRelayerConfiguration
    ) async throws -> String

    func signRelayTransaction(
        _ preparedTransaction: PreparedTransaction,
        config configuration: FeeRelayerConfiguration
    ) async throws -> String

    func topUpIfNeededAndRelayTransactions(
        _ preparedTransaction: [PreparedTransaction],
        fee payingFeeToken: TokenAccount?,
        config configuration: FeeRelayerConfiguration
    ) async throws -> [TransactionID]

    func topUpIfNeededAndSignRelayTransactions(
        _ preparedTransaction: [PreparedTransaction],
        fee payingFeeToken: TokenAccount?,
        config configuration: FeeRelayerConfiguration
    ) async throws -> [TransactionID]

    /// Top up user relay account
    func topUp(
        amount: FeeAmount,
        payingFeeToken: TokenAccount?,
        relayContext: RelayContext
    ) async throws -> [TransactionID]?

    /// Verify and sign transaction.
    func signTransaction(
        transactions: [VersionedTransaction],
        config configuration: FeeRelayerConfiguration
    ) async throws -> [VersionedTransaction]
}

public extension RelayService {
    /// Top up (if needed) and relay transaction to RelayService
    /// - Parameters:
    ///   - transaction: transaction that needs to be relayed
    ///   - fee: token to pay fee
    ///   - config: relay's configuration
    /// - Returns: transaction's signature
    func topUpIfNeededAndRelayTransaction(
        _ transaction: PreparedTransaction,
        fee: TokenAccount?,
        config: FeeRelayerConfiguration
    ) async throws -> TransactionID {
        try await topUpIfNeededAndRelayTransactions([transaction], fee: fee, config: config).first
            ?! FeeRelayerError.unknown
    }

    /// Top up (if needed) and get feePayer's signature for a transaction
    /// - Parameters:
    ///   - transaction: transaction that needs feePayer's signature
    ///   - fee: token to pay fee
    ///   - config: relay's configuration
    /// - Returns: feePayer's signature
    func topUpIfNeededAndSignRelayTransactions(
        _ transaction: PreparedTransaction,
        fee: TokenAccount?,
        config: FeeRelayerConfiguration
    ) async throws -> TransactionID {
        try await topUpIfNeededAndSignRelayTransactions([transaction], fee: fee, config: config).first
            ?! FeeRelayerError.unknown
    }
}
