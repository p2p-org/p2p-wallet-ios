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
    var recipientSectionsDriver: Driver<[RecipientsSection]> { get }
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
        private let recipientSectionsSubject = BehaviorRelay<[RecipientsSection]>(value: [])
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)

        init(nameService: NameServiceType) {
            self.nameService = nameService

            bind()
        }
    }
}

extension SelectRecipient.ViewModel: SelectRecipientViewModelType {
    var recipientSectionsDriver: Driver<[RecipientsSection]> {
        recipientSectionsSubject
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
            return recipientSectionsSubject.accept([])
        }

        // < 40 is a logic from web
        text.count < 40 ? findRecipientsBy(name: text) : findRecipientBy(address: text)
    }

    private func findRecipientsBy(name: String) {
        nameService
            .getOwners(name)
            .map {
                $0.map { Recipient(address: $0.owner, name: $0.name) }
            }
            .map {
                $0.isEmpty ? [] : [RecipientsSection(header: L10n.foundAssociatedWalletAddress, items: $0)]
            }
            .subscribe(
                onSuccess: { [weak self] recipientSections in
                    self?.recipientSectionsSubject.accept(recipientSections)
                },
                onFailure: { _ in }
            )
            .disposed(by: disposeBag)
    }

    private func findRecipientBy(address: String) {
        nameService
            .getName(address)
            .map {
                [Recipient(address: address, name: $0)]
            }
            .map {
                [RecipientsSection(header: L10n.result, items: $0)]
            }
            .subscribe(
                onSuccess: { [weak self] recipientSections in
                    self?.recipientSectionsSubject.accept(recipientSections)
                },
                onFailure: { _ in }
            )
            .disposed(by: disposeBag)
    }
}
