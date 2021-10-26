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
        
        // MARK: - Subject
        let recipientSearchSubject = BehaviorRelay<String?>(value: nil)
        private let recipientSectionsSubject = BehaviorRelay<[RecipientsSection]>(value: [])
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)

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
                .map { [weak addressFormatter] in
                    guard let addressFormatter = addressFormatter else { return [] }

                    return $0.map {
                        Recipient(
                            address: $0.owner,
                            shortAddress: addressFormatter.shortAddress(of: $0.owner),
                            name: $0.name
                        )
                    }
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
                .map { [weak addressFormatter] in
                    guard let addressFormatter = addressFormatter else { return [] }

                    let recipient = Recipient(
                        address: address,
                        shortAddress: addressFormatter.shortAddress(of: address),
                        name: $0
                    )

                    return [recipient]
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
