//
//  BurnAndReleasePersistentStore.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2022.
//

import Foundation
import RenVMSwift

class RenVMBurnAndReleasePersistentStore: BurnAndReleasePersistentStore {
    func getNonReleasedTransactions() -> [BurnAndRelease.BurnDetails] {
        Defaults.renVMSubmitedBurnTxDetails
    }

    func persistNonReleasedTransactions(_ details: BurnAndRelease.BurnDetails) {
        var currentValue = Defaults.renVMSubmitedBurnTxDetails
        currentValue.removeAll(where: { $0.confirmedSignature == details.confirmedSignature })
        currentValue.append(details)
        Defaults.renVMSubmitedBurnTxDetails = currentValue
    }

    func markAsReleased(_ details: BurnAndRelease.BurnDetails) {
        var currentValue = Defaults.renVMSubmitedBurnTxDetails
        currentValue.removeAll(where: { $0.confirmedSignature == details.confirmedSignature })
        Defaults.renVMSubmitedBurnTxDetails = currentValue
    }
}
