//
//  RenVM.LockAndMint.SessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation
import RenVMSwift
import RxCocoa

extension RenVM.LockAndMint {
    struct ProcessingTx: Codable, Hashable {
        static let maxVote: UInt64 = 3
        var tx: TxDetail
        var receivedAt: Date?
        var oneVoteAt: Date?
        var twoVoteAt: Date?
        var threeVoteAt: Date?
        var confirmedAt: Date?
        var submittedAt: Date?
        var mintedAt: Date?

        var statusString: String? {
            if mintedAt != nil {
                return L10n.successfullyMintedRenBTC(
                    tx.value.convertToBalance(decimals: 8)
                        .toString(maximumFractionDigits: 9)
                )
            }

            if submittedAt != nil {
                return L10n.minting
            }

            if confirmedAt != nil {
                return L10n.submittingToRenVM
            }

            if receivedAt != nil {
                return L10n.waitingForDepositConfirmation + " \(tx.vout)/\(Self.maxVote)"
            }

            return nil
        }

        var value: Double {
            tx.value.convertToBalance(decimals: 8)
        }
    }
}

protocol RenVMLockAndMintSessionStorageType {
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> { get }

    func loadSession() -> RenVM.Session?
    func saveSession(_ session: RenVM.Session)
    func expireCurrentSession()

    func processingTx(tx: RenVM.LockAndMint.TxDetail, didReceiveAt receivedAt: Date)
    func processingTx(tx: RenVM.LockAndMint.TxDetail, didConfirmAt confirmedAt: Date)
    func processingTx(tx: RenVM.LockAndMint.TxDetail, didSubmitAt submittedAt: Date)
    func processingTx(tx: RenVM.LockAndMint.TxDetail, didMintAt mintedAt: Date)

    func isMinted(txid: String) -> Bool
    func getProcessingTx(txid: String) -> RenVM.LockAndMint.ProcessingTx?
    func getAllProcessingTx() -> [RenVM.LockAndMint.ProcessingTx]
    func removeMintedTx(txid: String)
}

extension RenVM.LockAndMint {
    class SessionStorage: RenVMLockAndMintSessionStorageType {
        private let processingTxsSubject = BehaviorRelay<[ProcessingTx]>(value: Defaults.renVMProcessingTxs)
        private var disposable: DefaultsDisposable!
        let lock = NSLock()

        init() {
            disposable = Defaults.observe(\.renVMProcessingTxs, handler: { [weak self] update in
                self?.processingTxsSubject.accept(update.newValue ?? [])
            })
        }

        var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {
            processingTxsSubject.asDriver()
        }

        func loadSession() -> RenVM.Session? {
            Defaults.renVMSession
        }

        func saveSession(_ session: RenVM.Session) {
            Defaults.renVMSession = session
        }

        func expireCurrentSession() {
            Defaults.renVMSession = nil
            Defaults.renVMProcessingTxs = []
        }

        func processingTx(tx: RenVM.LockAndMint.TxDetail, didReceiveAt receivedAt: Date) {
            save { current in
                guard let index = current.indexOf(tx) else {
                    current.append(.init(tx: tx, receivedAt: receivedAt))
                    return true
                }

                if tx.vout == 3, current[index].threeVoteAt == nil {
                    current[index].threeVoteAt = receivedAt
                }
                if tx.vout == 2, current[index].twoVoteAt == nil {
                    current[index].twoVoteAt = receivedAt
                }
                if tx.vout == 1, current[index].oneVoteAt == nil {
                    current[index].oneVoteAt = receivedAt
                }
                if tx.vout == 0, current[index].receivedAt == nil {
                    current[index].receivedAt = receivedAt
                }

                return true
            }
        }

        func processingTx(tx: RenVM.LockAndMint.TxDetail, didConfirmAt confirmedAt: Date) {
            save { current in
                guard let index = current.indexOf(tx) else {
                    current.append(.init(tx: tx, confirmedAt: confirmedAt))
                    return true
                }
                current[index].confirmedAt = confirmedAt
                return true
            }
        }

        func processingTx(tx: RenVM.LockAndMint.TxDetail, didSubmitAt submittedAt: Date) {
            save { current in
                guard let index = current.indexOf(tx) else {
                    current.append(.init(tx: tx, submittedAt: submittedAt))
                    return true
                }
                current[index].submittedAt = submittedAt
                return true
            }
        }

        func processingTx(tx: RenVM.LockAndMint.TxDetail, didMintAt mintedAt: Date) {
            save { current in
                guard let index = current.indexOf(tx) else {
                    current.append(.init(tx: tx, mintedAt: mintedAt))
                    return true
                }
                current[index].mintedAt = mintedAt
                return true
            }
        }

        func isMinted(txid: String) -> Bool {
            getAllProcessingTx().contains(where: { $0.tx.txid == txid && $0.mintedAt != nil })
        }

        func getProcessingTx(txid: String) -> RenVM.LockAndMint.ProcessingTx? {
            Defaults.renVMProcessingTxs.first(where: { $0.tx.txid == txid })
        }

        func getAllProcessingTx() -> [RenVM.LockAndMint.ProcessingTx] {
            Defaults.renVMProcessingTxs
        }

        func removeMintedTx(txid: String) {
            lock.lock()
            defer { lock.unlock() }

            var current = Defaults.renVMProcessingTxs
            current.removeAll(where: { $0.tx.txid == txid })
            Defaults.renVMProcessingTxs = current
        }

        private func save(_ modify: @escaping (inout [RenVM.LockAndMint.ProcessingTx]) -> Bool) {
            lock.lock()
            defer { lock.unlock() }

            var current = Defaults.renVMProcessingTxs
            let shouldSave = modify(&current)
            if shouldSave && Defaults.renVMProcessingTxs != current {
                Defaults.renVMProcessingTxs = current
            }
        }
    }
}

private extension Array where Element == RenVM.LockAndMint.ProcessingTx {
    func hasTx(_ tx: RenVM.LockAndMint.TxDetail) -> Bool {
        contains(where: { $0.tx.txid == tx.txid })
    }

    func indexOf(_ tx: RenVM.LockAndMint.TxDetail) -> Int? {
        firstIndex(where: { $0.tx.txid == tx.txid })
    }
}
