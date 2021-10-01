//
//  RenVM.LockAndMint.SessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation
import RxCocoa

extension RenVM.LockAndMint {
    struct ProcessingTx: Codable {
        enum Status: String, Codable {
            case waitingForConfirmation, confirmed, submitting, submitted, minting, minted
        }
        var tx: TxDetail
        var status: Status
        var updatedAt: Date
    }
}

protocol RenVMLockAndMintSessionStorageType {
    func loadSession() -> RenVM.Session?
    func saveSession(_ session: RenVM.Session)
    func expireCurrentSession()
    
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {get}
    func set(_ status: RenVM.LockAndMint.ProcessingTx.Status, for txDetail: RenVM.LockAndMint.TxDetail)
    func isMinted(txid: String) -> Bool
    func isProcessing(txid: String) -> Bool
}

extension RenVM.LockAndMint {
    class SessionStorage: RenVMLockAndMintSessionStorageType {
        private let processingTxsSubject = BehaviorRelay<[ProcessingTx]>(value: Defaults.renVMProcessingTxs)
        private var disposable: DefaultsDisposable!
        
        init() {
            disposable = Defaults.observe(\.renVMProcessingTxs, handler: { [weak self] update in
                self?.processingTxsSubject.accept(update.newValue ?? [])
            })
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
        
        var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {
            processingTxsSubject.asDriver()
        }
        
        func set(
            _ status: RenVM.LockAndMint.ProcessingTx.Status,
            for txDetail: RenVM.LockAndMint.TxDetail
        ) {
            Defaults.renVMProcessingTxs = Defaults.renVMProcessingTxs.seted(status, for: txDetail)
        }
        
        func isMinted(txid: String) -> Bool {
            guard let tx = Defaults.renVMProcessingTxs.first(where: {$0.tx.txid == txid})
            else { return false }
            return tx.status == .minted
        }
        
        func isProcessing(txid: String) -> Bool {
            guard let tx = Defaults.renVMProcessingTxs.first(where: {$0.tx.txid == txid})
            else {return false}
            return tx.status == .submitting || tx.status == .minting
        }
//
//        func isSubmited(txid: String) -> Bool {
//            Defaults.renVMProcessingTxs.contains(where: {$0.tx.txid == txid})
//        }
//
//        func setAsMinted(tx: TxDetail) {
//            var txs = Defaults.renVMProcessingTxs
//
//            if let index = txs.firstIndex(where: {$0.tx.txid == tx.txid}) {
//                var tx = txs[index]
//                tx.isMinted = true
//                txs[index] = tx
//            }
//
//            Defaults.renVMProcessingTxs = txs
//        }
//
//        func setAsSubmited(tx: TxDetail) {
//            if Defaults.renVMProcessingTxs.contains(where: {$0.tx.txid == tx.txid}) {return}
//            var txs = Defaults.renVMProcessingTxs
//            txs.append(.init(tx: tx, isMinted: false))
//            Defaults.renVMProcessingTxs = txs
//        }
//
//        func getSubmitedButUnmintedTxId() -> [TxDetail] {
//            Defaults.renVMProcessingTxs.filter {$0.isMinted == false}.map {$0.tx}
//        }
    }
}

private extension Array where Element == RenVM.LockAndMint.ProcessingTx {
    func seted(_ status: RenVM.LockAndMint.ProcessingTx.Status, for txDetail: RenVM.LockAndMint.TxDetail) -> Self
    {
        var current = self
        if let index = current.firstIndex(where: {$0.tx.txid == txDetail.txid}) {
            current[index].tx = txDetail
            current[index].status = status
            current[index].updatedAt = Date()
        } else {
            current.append(
                .init(
                    tx: txDetail,
                    status: status,
                    updatedAt: Date()
                )
            )
        }
        return current
    }
}
