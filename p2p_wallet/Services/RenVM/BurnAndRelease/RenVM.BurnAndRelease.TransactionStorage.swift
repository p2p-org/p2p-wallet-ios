//
//  RenVM.BurnAndRelease.TransactionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/09/2021.
//

import Foundation
import RenVMSwift
import RxCocoa
import RxSwift

protocol RenVMBurnAndReleaseTransactionStorageType {
//    func burnTransactionObservable() -> Observable<[RenVM.BurnAndRelease.BurnDetails]> // MEMORY LEAK
    var newSubmittedBurnTxDetailsHandler: (([RenVM.BurnAndRelease.BurnDetails]) -> Void)? { get set }
    func setSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails)
    func releaseSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails)
}

extension RenVM.BurnAndRelease {
    class TransactionStorage: RenVMBurnAndReleaseTransactionStorageType {
        var newSubmittedBurnTxDetailsHandler: (([RenVM.BurnAndRelease.BurnDetails]) -> Void)?
        var disposable: DefaultsDisposable?

        init() {
            disposable = Defaults.observe(\.renVMSubmitedBurnTxDetails) { [weak self] update in
                self?.newSubmittedBurnTxDetailsHandler?(update.newValue ?? [])
            }
        }

        func setSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails) {
            var currentValue = Defaults.renVMSubmitedBurnTxDetails
            currentValue.removeAll(where: { $0.confirmedSignature == details.confirmedSignature })
            currentValue.append(details)
            Defaults.renVMSubmitedBurnTxDetails = currentValue
        }

        func releaseSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails) {
            var currentValue = Defaults.renVMSubmitedBurnTxDetails
            currentValue.removeAll(where: { $0.confirmedSignature == details.confirmedSignature })
            Defaults.renVMSubmitedBurnTxDetails = currentValue
        }
    }
}
