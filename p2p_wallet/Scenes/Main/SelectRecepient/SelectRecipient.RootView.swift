//
//  SelectRecipient.RootView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 20.10.2021.
//

import UIKit
import RxSwift
import BECollectionView

extension SelectRecipient {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: SelectRecipientViewModelType
        
        // MARK: - Subviews
        private let navigationBar = TitleWithCloseButtonNavigationBar(title: L10n.recipient)
        private let addressView: UIView
        private let wrappedAddressView: UIView
        private lazy var recipientCollectionView: RecipientsCollectionView = {
            let collectionView = RecipientsCollectionView(recipientsListViewModel: viewModel.recipientsListViewModel)
            collectionView.delegate = self
            return collectionView
        }()
        private let errorLabel = UILabel(textSize: 15, weight: .regular, textColor: .ff4444, numberOfLines: 0)
        private lazy var toolBar = KeyboardDependingToolBar(
            nextHandler: { [weak self] in
                self?.endEditing(true)
            },
            pasteHandler: { [weak addressView] in
                addressView?.paste(nil)
            }
        )

        // MARK: - Methods
        init(viewModel: SelectRecipientViewModelType) {
            self.viewModel = viewModel

            self.addressView = AddressView(viewModel: viewModel)
            self.wrappedAddressView = addressView
                .padding(.init(all: 8), backgroundColor: .a3a5ba.onDarkMode(.h8d8d8d).withAlphaComponent(0.1), cornerRadius: 12)

            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()

            configureSubviews()
            layout()
            bind()
        }

        func startRecipientInput() {
            addressView.becomeFirstResponder()
        }

        // MARK: - Layout
        private func layout() {
            [navigationBar, wrappedAddressView, errorLabel, recipientCollectionView, toolBar].forEach(addSubview)

            navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)

            wrappedAddressView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            wrappedAddressView.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            wrappedAddressView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)

            errorLabel.autoPinEdge(.top, to: .bottom, of: wrappedAddressView, withOffset: 8)
            errorLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
            errorLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
            
            recipientCollectionView.autoPinEdge(.top, to: .bottom, of: wrappedAddressView)
            recipientCollectionView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)

            toolBar.setConstraints()
        }

        private func configureSubviews() {
            wrappedAddressView.layer.borderWidth = 1
            wrappedAddressView.layer.borderColor = UIColor.a3a5ba.withAlphaComponent(0.5).cgColor
        }
        
        private func bind() {
            navigationBar.closeObservable
                .subscribe(onNext: { [weak viewModel] in
                    viewModel?.closeScene()
                })
                .disposed(by: disposeBag)
            
            // error text
            let errorTextDriver = viewModel.recipientsListViewModel
                .dataDidChange
                .asDriver(onErrorJustReturn: ())
                .map { [weak self] _ -> String? in
                    guard let self = self else {return nil}
                    let vm = self.viewModel.recipientsListViewModel
                    
                    switch vm.currentState {
                    case .error:
                        return L10n.thereIsAnErrorOccuredPleaseTryTypingNameAgain
                    case .loaded where vm.searchString?.isEmpty != true && vm.data.isEmpty:
                        return L10n.thisUsernameIsNotAssociatedWithAnyone
                    default:
                        return nil
                    }
                }
                
            errorTextDriver.drive(errorLabel.rx.text)
                .disposed(by: disposeBag)

            let errorIsEmpty = errorTextDriver.map {$0 == nil}

            // error visibility
            errorIsEmpty
                .drive(errorLabel.rx.isHidden)
                .disposed(by: disposeBag)

            // collectionView visibility
            errorIsEmpty
                .map { !$0 }
                .drive(recipientCollectionView.rx.isHidden)
                .disposed(by: disposeBag)
        }
    }
}

extension SelectRecipient.RootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let recipient = item as? Recipient else {return}
        viewModel.recipientSelected(recipient)
    }
}
