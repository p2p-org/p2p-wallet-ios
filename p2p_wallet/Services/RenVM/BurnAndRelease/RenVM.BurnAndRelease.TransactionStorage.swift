//
//  RenVM.BurnAndRelease.TransactionStorage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/09/2021.
//

import Foundation

protocol RenVMBurnAndReleaseTransactionStorageType {
    func getSubmitedBurnTransactions() -> [RenVM.BurnAndRelease.BurnDetails]
    func setSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails)
    func releaseSubmitedBurnTransaction(_ details: RenVM.BurnAndRelease.BurnDetails)
}

extension RenVM.BurnAndRelease {
    struct TransactionStorage: RenVMBurnAndReleaseTransactionStorageType {
        func getSubmitedBurnTransactions() -> [RenVM.BurnAndRelease.BurnDetails] {
            Defaults.renVMSubmitedBurnTxDetails
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
