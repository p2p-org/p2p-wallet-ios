//
//  RenVM.BurnAndRelease.TransactionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol RenVMBurnAndReleaseTransactionStorageType {
    func burnTransactionObservable() -> Observable<[RenVM.BurnAndRelease.BurnDetails]>
    func setSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails)
    func releaseSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails)
}

extension RenVM.BurnAndRelease {
    class TransactionStorage: RenVMBurnAndReleaseTransactionStorageType {
        var disposable: DefaultsDisposable?
        var subject = PublishRelay<[RenVM.BurnAndRelease.BurnDetails]>()
        
        init() {
            disposable = Defaults.observe(\.renVMSubmitedBurnTxDetails) {[weak self] update in
                self?.subject.accept(update.newValue ?? [])
            }
        }
        
        func burnTransactionObservable() -> Observable<[RenVM.BurnAndRelease.BurnDetails]> {
            subject.distinctUntilChanged().asObservable()
        }
        
        func setSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails) {
            var currentValue = Defaults.renVMSubmitedBurnTxDetails
            currentValue.removeAll(where: {$0.confirmedSignature == details.confirmedSignature})
            currentValue.append(details)
            Defaults.renVMSubmitedBurnTxDetails = currentValue
        }
        
        func releaseSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails) {
            var currentValue = Defaults.renVMSubmitedBurnTxDetails
            currentValue.removeAll(where: {$0.confirmedSignature == details.confirmedSignature})
            Defaults.renVMSubmitedBurnTxDetails = currentValue
        }
    }
}
