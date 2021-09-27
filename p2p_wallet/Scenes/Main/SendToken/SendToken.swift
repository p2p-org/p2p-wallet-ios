//
//  Send.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2021.
//

import Foundation
import RxSwift

struct SendToken {
    enum NavigatableScene {
        case chooseWallet
        case chooseAddress
        case scanQrCode
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
        case feeInfo
    }
    
    enum CurrencyMode {
        case token, fiat
    }
    
    enum AddressValidationStatus {
        case uncheck
        case fetching
        case valid
        case invalid
        case fetchingError
        case invalidIgnored
    }
}
