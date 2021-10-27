//
//  SelectRecipient.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.10.2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol SelectRecipientViewModelType: AnyObject {
    var recipientsListViewModel: SelectRecipient.RecipientsListViewModel {get}
    
    var navigationDriver: Driver<SelectRecipient.NavigatableScene?> { get }
    var recipientSearchDriver: Driver<String?> { get }
    var searchErrorDriver: Driver<String?> { get }
    var recipientSearchSubject: BehaviorRelay<String?> { get }

    func recipientSelected(_: Recipient)
    func clearRecipientSearchText()
    func scanQRCode()
    func enterWalletAddress(_: String)
    
    func closeScene()
}

extension SelectRecipient {
    class ViewModel {
        // MARK: - Dependencies
        private let nameService: NameServiceType
        private let addressFormatter: AddressFormatterType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private let recipientSelectedHandler: (Recipient) -> Void
        
        let recipientsListViewModel = RecipientsListViewModel()
        
        // MARK: - Subject
        let recipientSearchSubject = BehaviorRelay<String?>(value: nil)
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let searchErrorSubject = BehaviorRelay<String?>(value: nil)

        init(
            nameService: NameServiceType,
            addressFormatter: AddressFormatterType,
            recipientSelectedHandler: @escaping ((Recipient) -> Void)
        ) {
            self.nameService = nameService
            self.addressFormatter = addressFormatter
            self.recipientSelectedHandler = recipientSelectedHandler

            bind()
        }

        private func bind() {
            recipientSearchSubject
                .subscribe(
                    onNext: { [weak self] searchText in
                        self?.recipientsListViewModel.name = searchText
                        self?.recipientsListViewModel.reload()
                    }
                )
                .disposed(by: disposeBag)
        }
    }
}

extension SelectRecipient.ViewModel: SelectRecipientViewModelType {
    var recipientSearchDriver: Driver<String?> {
        recipientSearchSubject.asDriver()
    }

    var navigationDriver: Driver<SelectRecipient.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var searchErrorDriver: Driver<String?> {
        searchErrorSubject.asDriver()
    }
    
    // MARK: - Actions
    func closeScene() {
        navigationSubject.accept(.close)
    }

    func clearRecipientSearchText() {
        recipientSearchSubject.accept(nil)
    }

    func recipientSelected(_ recipient: Recipient) {
        recipientSelectedHandler(recipient)
        navigationSubject.accept(.close)
    }

    func scanQRCode() {
        navigationSubject.accept(.scanQRCode)
    }

    func enterWalletAddress(_ address: String) {
        recipientSearchSubject.accept(address)
    }
}
