//
//  TransactionInfoViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import RxSwift
import RxCocoa
import Resolver

enum TransactionInfoNavigatableScene {
    case explorer
}

class TransactionInfoViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    
    // MARK: - Dependencies
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationsServiceType
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<TransactionInfoNavigatableScene>()
    let showDetailTransaction = BehaviorRelay<Bool>(value: false)
    var transaction: BehaviorRelay<SolanaSDK.ParsedTransaction>!
    
    // MARK: - Input
//    let textFieldInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    
    // MARK: - Methods
    func set(transaction: SolanaSDK.ParsedTransaction) {
        self.transaction = .init(value: transaction)
    }
    
    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }
    
    // MARK: - Actions
    @objc func showExplorer() {
        navigationSubject.onNext(.explorer)
    }
    
    @objc func toggleShowDetailTransaction() {
        showDetailTransaction.accept(!showDetailTransaction.value)
    }
    
    @objc func copySignatureToClipboard() {
        copyToClipboardAndShowNotification(transaction.value.signature)
    }
    
    @objc func copySourceAddressToClipboard() {
        switch transaction.value.value {
        case let transferTransaction as SolanaSDK.TransferTransaction:
            copyToClipboardAndShowNotification(transferTransaction.authority ?? transferTransaction.source?.pubkey)
        default:
            return
        }
    }
    
    @objc func copyDestinationAddressToClipboard() {
        switch transaction.value.value {
        case let transferTransaction as SolanaSDK.TransferTransaction:
            copyToClipboardAndShowNotification(transferTransaction.destinationAuthority ?? transferTransaction.destination?.pubkey)
        case let createAccountTransaction as SolanaSDK.CreateAccountTransaction:
            copyToClipboardAndShowNotification(createAccountTransaction.newWallet?.pubkey)
        default:
            return
        }
    }
    
    private func copyToClipboardAndShowNotification(_ text: String?) {
        guard let text = text else { return }

        clipboardManager.copyToClipboard(text)
        notificationsService.showInAppNotification(.done(L10n.copiedToClipboard))
    }
}
