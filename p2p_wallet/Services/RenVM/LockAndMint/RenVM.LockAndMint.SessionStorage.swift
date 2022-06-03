//
//  LockAndMint.SessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation
import RenVMSwift
import RxCocoa

// extension LockAndMint {
//    class SessionStorage: RenVMLockAndMintSessionStorageType {
//        private let processingTxsSubject = BehaviorRelay<[ProcessingTx]>(value: Defaults.renVMProcessingTxs)
//        private var disposable: DefaultsDisposable!
//        let lock = NSLock()
//
//        init() {
//            disposable = Defaults.observe(\.renVMProcessingTxs, handler: { [weak self] update in
//                self?.processingTxsSubject.accept(update.newValue ?? [])
//            })
//        }
//
//        var processingTxsDriver: Driver<[LockAndMint.ProcessingTx]> {
//            processingTxsSubject.asDriver()
//        }
//
//        func loadSession() -> RenVMSwift.Session? {
//            Defaults.renVMSession
//        }
//
//        func saveSession(_ session: RenVMSwift.Session) {
//            Defaults.renVMSession = session
//        }
//
//        func expireCurrentSession() {
//            Defaults.renVMSession = nil
//            Defaults.renVMProcessingTxs = []
//        }
//
//        func processingTx(tx: IncomingTransaction, didReceiveAt receivedAt: Date) {
//            save { current in
//                guard let index = current.indexOf(tx) else {
//                    current.append(.init(tx: tx, receivedAt: receivedAt))
//                    return true
//                }
//
//                if tx.vout == 3, current[index].threeVoteAt == nil {
//                    current[index].threeVoteAt = receivedAt
//                }
//                if tx.vout == 2, current[index].twoVoteAt == nil {
//                    current[index].twoVoteAt = receivedAt
//                }
//                if tx.vout == 1, current[index].oneVoteAt == nil {
//                    current[index].oneVoteAt = receivedAt
//                }
//                if tx.vout == 0, current[index].receivedAt == nil {
//                    current[index].receivedAt = receivedAt
//                }
//
//                return true
//            }
//        }
//
//        func processingTx(tx: IncomingTransaction, didConfirmAt confirmedAt: Date) {
//            save { current in
//                guard let index = current.indexOf(tx) else {
//                    current.append(.init(tx: tx, confirmedAt: confirmedAt))
//                    return true
//                }
//                current[index].confirmedAt = confirmedAt
//                return true
//            }
//        }
//
//        func processingTx(tx: IncomingTransaction, didSubmitAt submittedAt: Date) {
//            save { current in
//                guard let index = current.indexOf(tx) else {
//                    current.append(.init(tx: tx, submittedAt: submittedAt))
//                    return true
//                }
//                current[index].submittedAt = submittedAt
//                return true
//            }
//        }
//
//        func processingTx(tx: IncomingTransaction, didMintAt mintedAt: Date) {
//            save { current in
//                guard let index = current.indexOf(tx) else {
//                    current.append(.init(tx: tx, mintedAt: mintedAt))
//                    return true
//                }
//                current[index].mintedAt = mintedAt
//                return true
//            }
//        }
//
//        func isMinted(txid: String) -> Bool {
//            getAllProcessingTx().contains(where: { $0.tx.txid == txid && $0.mintedAt != nil })
//        }
//
//        func getProcessingTx(txid: String) -> LockAndMint.ProcessingTx? {
//            Defaults.renVMProcessingTxs.first(where: { $0.tx.txid == txid })
//        }
//
//        func getAllProcessingTx() -> [LockAndMint.ProcessingTx] {
//            Defaults.renVMProcessingTxs
//        }
//
//        func removeMintedTx(txid: String) {
//            lock.lock()
//            defer { lock.unlock() }
//
//            var current = Defaults.renVMProcessingTxs
//            current.removeAll(where: { $0.tx.txid == txid })
//            Defaults.renVMProcessingTxs = current
//        }
//
//        private func save(_ modify: @escaping (inout [LockAndMint.ProcessingTx]) -> Bool) {
//            lock.lock()
//            defer { lock.unlock() }
//
//            var current = Defaults.renVMProcessingTxs
//            let shouldSave = modify(&current)
//            if shouldSave && Defaults.renVMProcessingTxs != current {
//                Defaults.renVMProcessingTxs = current
//            }
//        }
//    }
// }
