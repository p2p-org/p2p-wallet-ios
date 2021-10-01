//
//  RenVM.LockAndMint.SessionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/09/2021.
//

import Foundation
import RxCocoa

extension RenVM.LockAndMint {
    struct ProcessingTx: Codable, Hashable {
        enum Status: String, Codable, Equatable {
            case waitingForConfirmation, confirmed, submitted, minted
        }
        var tx: TxDetail
        var status: Status
        var updatedAt: Date
        
        var stringValue: String {
            switch status {
            case .waitingForConfirmation:
                return L10n.waitingForDepositConfirmation
            case .confirmed:
                return L10n.submittingToRenVM
            case .submitted:
                return L10n.minting
            case .minted:
                return L10n.successfullyMintedRenBTC(
                    tx.value.convertToBalance(decimals: 8)
                        .toString(maximumFractionDigits: 9)
                )
            }
        }
    }
}

protocol RenVMLockAndMintSessionStorageType {
    func loadSession() -> RenVM.Session?
    func saveSession(_ session: RenVM.Session)
    func expireCurrentSession()
    
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {get}
    func set(_ status: RenVM.LockAndMint.ProcessingTx.Status, for txDetail: RenVM.LockAndMint.TxDetail)
    func isMinted(txid: String) -> Bool
    func getProcessingTx(txid: String) -> RenVM.LockAndMint.ProcessingTx?
    func getAllProcessingTx() -> [RenVM.LockAndMint.ProcessingTx]
    func removeMintedTx(txid: String)
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
        
        func getProcessingTx(txid: String) -> RenVM.LockAndMint.ProcessingTx? {
            Defaults.renVMProcessingTxs.first(where: {$0.tx.txid == txid})
        }
        
        func getAllProcessingTx() -> [RenVM.LockAndMint.ProcessingTx] {
            Defaults.renVMProcessingTxs
        }
        
        func removeMintedTx(txid: String) {
            var current = Defaults.renVMProcessingTxs
            current.removeAll(where: {$0.tx.txid == txid})
            Defaults.renVMProcessingTxs = current
        }
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
