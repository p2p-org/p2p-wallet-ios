//
//  InvestSolendBlindModel.swift
//  p2p_wallet
//
//  Created by Ivan on 27.09.2022.
//

import Foundation
import Solend

struct SolendTopUpForContinueModel {
    let asset: SolendConfigAsset
    let apy: Double?
    let strategy: Strategy

    enum Strategy {
        case withoutAnyTokens
        case withoutOnlyTokenForDeposit
    }
}
