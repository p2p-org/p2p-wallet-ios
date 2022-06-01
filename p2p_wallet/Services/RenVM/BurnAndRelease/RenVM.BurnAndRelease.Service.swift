//
//  BurnAndRelease.Service.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/09/2021.
//

import Foundation
import RenVMSwift
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol RenVMBurnAndReleaseServiceType {
    func isTestNet() -> Bool
    func getFee() async throws -> Double
    func burn(recipient: String, amount: UInt64) async throws -> String
}

extension BurnAndRelease {
    class Service: RenVMBurnAndReleaseServiceType {
        // MARK: - Nested type

        actor Cache {
            var burnAndRelease: BurnAndRelease?
            var releasingTxs = [BurnDetails]()

            func save(burnAndRelease: BurnAndRelease) {
                self.burnAndRelease = burnAndRelease
            }

            func save(releasingTx: BurnDetails) {
                releasingTxs.appendIfNotExist(releasingTx)
            }

            func markAsReleased(signature: String) {
                releasingTxs.removeAll(where: { $0.confirmedSignature == signature })
            }
        }

        // MARK: - Constants

        private let mintTokenSymbol = "BTC"
        private let version = "1"
        private let disposeBag = DisposeBag()

        // MARK: - Dependencies

        @Injected private var rpcClient: RenVMRpcClientType
        @Injected private var solanaAPIClient: SolanaAPIClient
        @Injected private var solanaBlockchainClient: SolanaBlockchainClient
        @Injected private var accountStorage: SolanaAccountStorage
        private var transactionStorage: RenVMBurnAndReleaseTransactionStorageType

        // MARK: - Properties

        private let cache = Cache()

        // MARK: - Initializer

        init(
            transactionStorage: RenVMBurnAndReleaseTransactionStorageType = TransactionStorage()
        ) {
            self.transactionStorage = transactionStorage

            bind()

            Task {
                try await reload()
            }
        }

        private func bind() {
            transactionStorage.newSubmittedBurnTxDetailsHandler = { burnDetails in
                Task { [weak self] in
                    guard let self = self else { return }
                    let releasingTxs = await self.cache.releasingTxs
                    let notYetBurnedTx = burnDetails.filter { !releasingTxs.contains($0) }

                    try await withThrowingTaskGroup(of: Void.self) { group in
                        for detail in notYetBurnedTx {
                            group.addTask { [weak self] in
                                guard let self = self else { throw RenVMError.unknown }
                                do {
                                    try await self.release(detail)
                                } catch {
                                    debugPrint(error)
                                }
                            }

                            for try await _ in group {}
                        }
                    }
                }
            }
        }

        private func reload() async throws {
            let solanaChain = try await SolanaChain.load(
                client: rpcClient,
                apiClient: solanaAPIClient,
                blockchainClient: solanaBlockchainClient
            )
            let burnAndRelease = BurnAndRelease(
                rpcClient: rpcClient,
                chain: solanaChain,
                mintTokenSymbol: mintTokenSymbol,
                version: version,
                burnTo: "Bitcoin"
            )
            await cache.save(burnAndRelease: burnAndRelease)
        }

        func isTestNet() -> Bool {
            rpcClient.network.isTestnet
        }

        func getFee() async throws -> Double {
            let lamports = try await rpcClient.getTransactionFee(mintTokenSymbol: mintTokenSymbol)
            return lamports.convertToBalance(decimals: 8)
        }

        func burn(recipient: String, amount: UInt64) async throws -> String {
            guard let account = accountStorage.account else {
                throw SolanaError.unauthorized
            }
            let burnAndRelease = try await getBurnAndRelease()
            let burnDetails = try await burnAndRelease.submitBurnTransaction(
                account: account.publicKey.data,
                amount: String(amount),
                recipient: recipient,
                signer: account.secretKey
            )
            transactionStorage.setSubmitedBurnTransaction(burnDetails)
            return burnDetails.confirmedSignature
        }

        private func release(_ detail: BurnDetails) async throws {
            // assertion
            if await cache.releasingTxs.contains(detail) { return }

            // mark as releasing
            await cache.save(releasingTx: detail)

            let burnAndRelease = try await getBurnAndRelease()
            let state = try burnAndRelease.getBurnState(burnDetails: detail)

            do {
                _ = try await Task.retrying(
                    where: { _ in true },
                    maxRetryCount: .max,
                    retryDelay: 3
                ) { () -> String in
                    try Task.checkCancellation()
                    return try await burnAndRelease.release(state: state, details: detail)
                }.value

                await cache.markAsReleased(signature: detail.confirmedSignature)
                transactionStorage.releaseSubmitedBurnTransaction(detail)
            } catch {
                await cache.markAsReleased(signature: detail.confirmedSignature)
            }
        }

        private func getBurnAndRelease() async throws -> BurnAndRelease {
            if await cache.burnAndRelease == nil {
                try await reload()
            }
            if let burnAndRelease = await cache.burnAndRelease {
                return burnAndRelease
            }
            throw RenVMError("Could not initialize burn and release service")
        }
    }
}
