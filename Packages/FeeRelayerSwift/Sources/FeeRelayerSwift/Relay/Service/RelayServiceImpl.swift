// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import OrcaSwapSwift
import SolanaSwift

/// Default implementation of RelayService
public class RelayServiceImpl: RelayService {
    // MARK: - Properties

    /// RelayContext manager
    let contextManager: RelayContextManager

    /// Client that interacts with fee relayer service
    private(set) var feeRelayerAPIClient: FeeRelayerAPIClient

    /// Client that interacts with solana rpc client
    private(set) var solanaApiClient: SolanaAPIClient

    /// Swap provider client
    private(set) var orcaSwap: OrcaSwapType

    /// Account storage that hold solana account
    private(set) var accountStorage: SolanaAccountStorage

    /// Fee calculator for RelayService
    public let feeCalculator: RelayFeeCalculator

    /// Device type for analysis
    let deviceType: StatsInfo.DeviceType

    /// Build number for analysis
    let buildNumber: String?

    /// Environment for analysis
    let environment: StatsInfo.Environment

    /// Solana account
    public var account: KeyPair {
        accountStorage.account!
    }

    // MARK: - Initializer

    /// RelayServiceImpl initializer
    public init(
        contextManager: RelayContextManager,
        orcaSwap: OrcaSwapType,
        accountStorage: SolanaAccountStorage,
        solanaApiClient: SolanaAPIClient,
        feeCalculator: RelayFeeCalculator = DefaultRelayFeeCalculator(),
        feeRelayerAPIClient: FeeRelayerAPIClient,
        deviceType: StatsInfo.DeviceType,
        buildNumber: String?,
        environment: StatsInfo.Environment
    ) {
        self.contextManager = contextManager
        self.solanaApiClient = solanaApiClient
        self.accountStorage = accountStorage
        self.feeCalculator = feeCalculator
        self.orcaSwap = orcaSwap
        self.feeRelayerAPIClient = feeRelayerAPIClient
        self.deviceType = deviceType
        self.buildNumber = buildNumber
        self.environment = environment
    }

    // MARK: - FeeRelayer v1: relay transaction directly

    /// Relay transaction to RelayService without topup
    /// - Parameters:
    ///   - preparedTransaction: preparedTransaction that have to be relayed
    ///   - configuration: relay's configuration
    /// - Returns: transaction's signature
    public func relayTransaction(
        _ preparedTransaction: PreparedTransaction,
        config configuration: FeeRelayerConfiguration
    ) async throws -> String {
        try await feeRelayerAPIClient.sendTransaction(.relayTransaction(
            try .init(
                preparedTransaction: preparedTransaction,
                statsInfo: .init(
                    operationType: configuration.operationType,
                    deviceType: deviceType,
                    currency: configuration.currency,
                    build: buildNumber,
                    environment: environment
                )
            )
        ))
    }

    /// Get fee payer's signature without topup
    /// - Parameters:
    ///   - preparedTransaction: preparedTransaction that have to be relayed
    ///   - configuration: relay's configuration
    /// - Returns: feePayer's signature
    public func signRelayTransaction(
        _ preparedTransaction: PreparedTransaction,
        config configuration: FeeRelayerConfiguration
    ) async throws -> String {
        try await feeRelayerAPIClient.sendTransaction(.signRelayTransaction(
            try .init(
                preparedTransaction: preparedTransaction,
                statsInfo: .init(
                    operationType: configuration.operationType,
                    deviceType: deviceType,
                    currency: configuration.currency,
                    build: buildNumber,
                    environment: environment
                )
            )
        ))
    }

    /// Top up (if needed) and relay multiple transactions to RelayService
    /// - Parameters:
    ///   - transactions: transactions that need to be relayed
    ///   - fee: token to pay fee
    ///   - config: relay's configuration
    /// - Returns: transaction's signature
    public func topUpIfNeededAndRelayTransactions(
        _ transactions: [PreparedTransaction],
        fee: TokenAccount?,
        config: FeeRelayerConfiguration
    ) async throws -> [TransactionID] {
        try await topUpIfNeededAndRelayTransactions(transactions, getSignatureOnly: false, fee: fee, config: config)
    }

    // MARK: - FeeRelayer v2: get feePayer's signature only

    /// Top up (if needed) and get feePayer's signature for multiple transactions
    /// - Parameters:
    ///   - transactions: transactions that needs feePayer's signature
    ///   - fee: token to pay fee
    ///   - config: relay's configuration
    /// - Returns: feePayer's signatures for transactions
    public func topUpIfNeededAndSignRelayTransactions(
        _ transactions: [SolanaSwift.PreparedTransaction],
        fee: TokenAccount?,
        config: FeeRelayerConfiguration
    ) async throws -> [TransactionID] {
        try await topUpIfNeededAndRelayTransactions(transactions, getSignatureOnly: true, fee: fee, config: config)
    }

    // MARK: - Helpers

    private func topUpIfNeededAndRelayTransactions(
        _ transactions: [SolanaSwift.PreparedTransaction],
        getSignatureOnly: Bool,
        fee: TokenAccount?,
        config: FeeRelayerConfiguration
    ) async throws -> [String] {
        // update and get current context
        try await contextManager.update()
        var context = contextManager.currentContext!

        // get expected fee
        let expectedFees = transactions.map(\.expectedFee)

        // do top up
        let res = try await topUpIfNeeded(
            expectedFee: .init(
                transaction: expectedFees.map(\.transaction).reduce(UInt64(0), +),
                accountBalances: expectedFees.map(\.accountBalances).reduce(UInt64(0), +)
            ),
            payingFeeToken: fee
        )

        // check if topped up
        let toppedUp = res != nil

        // update context locally after topping up
        if toppedUp {
            context.usageStatus.currentUsage += 1
            context.usageStatus.amountUsed += context.lamportsPerSignature * 2 // fee for top up has been used
            contextManager.replaceContext(by: context)
        }

        do {
            var trx: [String] = []

            // relay transactions
            for (index, preparedTransaction) in transactions.enumerated() {
                // relay each transactions
                let preparedRelayTransaction = try await prepareRelayTransaction(
                    preparedTransaction: preparedTransaction,
                    payingFeeToken: fee,
                    relayAccountStatus: context.relayAccountStatus,
                    additionalPaybackFee: index == transactions.count - 1 ? config.additionalPaybackFee : 0,
                    operationType: config.operationType,
                    currency: config.currency,
                    autoPayback: config.autoPayback
                )

                let signature: String

                if getSignatureOnly {
                    signature = try await feeRelayerAPIClient.sendTransaction(.signRelayTransaction(
                        try .init(
                            preparedTransaction: preparedRelayTransaction,
                            statsInfo: .init(
                                operationType: config.operationType,
                                deviceType: deviceType,
                                currency: config.currency,
                                build: buildNumber,
                                environment: environment
                            )
                        )
                    ))
                } else {
                    signature = try await feeRelayerAPIClient.sendTransaction(.relayTransaction(
                        try .init(
                            preparedTransaction: preparedRelayTransaction,
                            statsInfo: .init(
                                operationType: config.operationType,
                                deviceType: deviceType,
                                currency: config.currency,
                                build: buildNumber,
                                environment: environment
                            )
                        )
                    ))
                }

                trx.append(signature)

                // update context for next transaction
                context.usageStatus.currentUsage += 1
                context.usageStatus.amountUsed += preparedTransaction.expectedFee.transaction
                contextManager.replaceContext(by: context)

                // wait for transaction to finish if transaction is not the last one
                if !getSignatureOnly, index < transactions.count - 1 {
                    try await solanaApiClient.waitForConfirmation(signature: signature, ignoreStatus: true)
                }
            }

            return trx
        } catch {
            if toppedUp {
                let responseError: SolanaSwift.ResponseError?
                switch error {
                case SolanaSwift.APIClientError.responseError(let detail):
                    responseError = detail
                default:
                    responseError = nil
                }
                throw FeeRelayerError.topUpSuccessButTransactionThrows(logs: responseError?.data?.logs)
            }
            throw error
        }
    }

    public func topUp(
        amount: FeeAmount,
        payingFeeToken: TokenAccount?,
        relayContext: RelayContext
    ) async throws -> [TransactionID]? {
        // update and get current context
        var relayContext = relayContext
        guard relayContext == contextManager.currentContext else {
            throw FeeRelayerError.inconsistenceRelayContext
        }

        // do top up
        let topUpResult = try await topUpIfNeeded(
            expectedFee: .init(
                transaction: amount.transaction,
                accountBalances: amount.accountBalances
            ),
            payingFeeToken: payingFeeToken
        )

        // If top up wasn't needed, we return nils
        guard let topUpResult else {
            return nil
        }

        // update context locally after topping up
        relayContext.usageStatus.currentUsage += 1
        relayContext.usageStatus.amountUsed += relayContext.lamportsPerSignature * 2
        contextManager.replaceContext(by: relayContext)

        return topUpResult
    }

    public func signTransaction(
        transactions: [VersionedTransaction],
        config: FeeRelayerConfiguration
    ) async throws -> [VersionedTransaction] {
        guard let feePayerAddress = contextManager.currentContext?.feePayerAddress else {
            throw FeeRelayerError.missingRelayFeePayer
        }

        var transactions = transactions
        
        for (idx, transaction) in transactions.enumerated() {
            /// Sign transaction
            let signature = try await feeRelayerAPIClient
                .sendTransaction(
                    .signRelayTransaction(
                        .init(
                            transaction: transaction,
                            statsInfo: .init(
                                operationType: config.operationType,
                                deviceType: deviceType,
                                currency: config.currency,
                                build: buildNumber,
                                environment: environment
                            )
                        )
                    )
                )

            var transaction = transaction
            try transaction.addSignature(
                publicKey: feePayerAddress,
                signature: Data(Base58.decode(signature))
            )

            transactions[idx] = transaction
        }
        
        return transactions
    }
}
