//
//  TransactionInfoViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import RxSwift
import RxCocoa

enum TransactionInfoNavigatableScene {
    case explorer
}

class TransactionInfoViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<TransactionInfoNavigatableScene>()
    let showDetailTransaction = BehaviorRelay<Bool>(value: false)
    let transaction: BehaviorRelay<ParsedTransaction>
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(transaction: ParsedTransaction) {
        self.transaction = BehaviorRelay<ParsedTransaction>(value: transaction)
    }
    
    // MARK: - Actions
    @objc func showExplorer() {
        navigationSubject.onNext(.explorer)
    }
    
    @objc func toggleShowDetailTransaction() {
        showDetailTransaction.accept(!showDetailTransaction.value)
    }
    
    @objc func copySignatureToClipboard() {
        UIApplication.shared.copyToClipboard(transaction.value.parsed?.signature)
    }
    
    @objc func copySourceAddressToClipboard() {
        switch transaction.value.parsed?.value {
        case let transferTransaction as SolanaSDK.TransferTransaction:
            UIApplication.shared.copyToClipboard(transferTransaction.source?.pubkey)
        default:
            return
        }
    }
    
    @objc func copyDestinationAddressToClipboard() {
        switch transaction.value.parsed?.value {
        case let transferTransaction as SolanaSDK.TransferTransaction:
            UIApplication.shared.copyToClipboard(transferTransaction.destination?.pubkey)
        case let createAccountTransaction as SolanaSDK.CreateAccountTransaction:
            UIApplication.shared.copyToClipboard(createAccountTransaction.newWallet?.pubkey)
        default:
            return
        }
    }
}
