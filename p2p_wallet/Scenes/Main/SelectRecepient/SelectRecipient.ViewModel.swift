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
    var navigationDriver: Driver<SelectRecipient.NavigatableScene?> { get }
    var recipientSearchDriver: Driver<String?> { get }
    var recipientsDriver: Driver<[Recipient]> { get }
    var recipientSearchSubject: BehaviorRelay<String?> { get }

    func recipientSelected(_: Recipient)
    func clearRecipientSearchText()
    func scanQRCode()
    
    func closeScene()
}

extension SelectRecipient {
    class ViewModel {
        // MARK: - Dependencies
        private let nameService: NameServiceType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subject
        let recipientSearchSubject = BehaviorRelay<String?>(value: nil)
        private let recipientsSubject = BehaviorRelay<[Recipient]>(value: [])
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)

        init(nameService: NameServiceType) {
            self.nameService = nameService

            bind()
        }
    }
}

extension SelectRecipient.ViewModel: SelectRecipientViewModelType {
    var recipientsDriver: Driver<[Recipient]> {
        recipientsSubject
            .asDriver()
    }

    var recipientSearchDriver: Driver<String?> {
        recipientSearchSubject.asDriver()
    }

    var navigationDriver: Driver<SelectRecipient.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    // MARK: - Actions
    func closeScene() {
        navigationSubject.accept(.close)
    }

    func clearRecipientSearchText() {
        recipientSearchSubject.accept(nil)
    }

    func recipientSelected(_ recipient: Recipient) {
        
    }

    func scanQRCode() {

    }

    private func bind() {
        recipientSearchSubject
            .subscribe(
                onNext: { [weak self] searchText in
                    self?.findRecipients(for: searchText)
                }
            )
            .disposed(by: disposeBag)
    }

    private func findRecipients(for text: String?) {
        guard let text = text, !text.isEmpty else {
            return recipientsSubject.accept([])
        }

        // < 40 is a logic from web
        text.count < 40 ? findRecipientsBy(name: text) : findRecipientBy(address: text)
    }

    private func findRecipientsBy(name: String) {
        nameService
            .getOwners(name)
            .map {
                $0.map{ Recipient(address: $0.owner, name: $0.name)}
            }
            .subscribe(
                onSuccess: { [weak self] recipients in
                    self?.recipientsSubject.accept(recipients)
                },
                onFailure: { _ in }
            )
            .disposed(by: disposeBag)
    }

    private func findRecipientBy(address: String) {
        nameService
            .getName(address)
            .subscribe(
                onSuccess: { [weak self] name in
                    self?.recipientsSubject.accept([.init(address: address, name: name)])
                },
                onFailure: { _ in }
            )
            .disposed(by: disposeBag)
    }
}
