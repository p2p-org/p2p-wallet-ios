//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import UIKit
import RxSwift
import RxCocoa
import BEPureLayout
import BECollectionView

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        
        // MARK: - Subviews
        private lazy var titleView = TitleView(viewModel: viewModel)
        private lazy var addressInputView = AddressInputView(viewModel: viewModel)
        private lazy var recipientView: RecipientView = {
            let view = RecipientView()
            view.addArrangedSubview(
                UIImageView(width: 17, height: 17, image: .crossIcon)
                    .onTap(self, action: #selector(clearRecipientButtonDidTouch))
            )
            return view
        }()
        private lazy var recipientCollectionView: RecipientsCollectionView = {
            let collectionView = RecipientsCollectionView(recipientsListViewModel: viewModel.recipientsListViewModel)
            collectionView.delegate = self
            return collectionView
        }()
        private lazy var networkView = NetworkView(forConvenience: ())
        private lazy var noAddressView = UIStackView(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill) {
            UIImageView(width: 44, height: 44, image: .errorUserAvatar)
            UILabel(text: L10n.thereSNoAddressLikeThis, textSize: 17, textColor: .ff3b30, numberOfLines: 0)
        }
            .padding(.init(x: 20, y: 0))
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        deinit {
            debugPrint("RootView deinited")
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        // MARK: - Layout
        private func layout() {
            scrollView.contentInset.modify(dTop: -.defaultPadding)
            stackView.addArrangedSubviews {
                UIView.floatingPanel {
                    titleView
                    BEStackViewSpacing(20)
                    addressInputView
                    recipientView
                }
                BEStackViewSpacing(18)
                networkView
                noAddressView
                recipientCollectionView
            }
            
            recipientCollectionView.autoPinEdge(.bottom, to: .bottom, of: self)
        }
        
        private func bind() {
            // input state
            let isSearchingDriver = viewModel.inputStateDriver
                .map {$0 == .searching}
                .distinctUntilChanged()
            
            isSearchingDriver.map {!$0}
                .drive(addressInputView.rx.isHidden)
                .disposed(by: disposeBag)
            
            isSearchingDriver
                .drive(recipientView.rx.isHidden)
                .disposed(by: disposeBag)
            
            isSearchingDriver.map {!$0}
                .drive(recipientCollectionView.rx.isHidden)
                .disposed(by: disposeBag)
            
            isSearchingDriver
                .drive(networkView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.recipientsListViewModel
                .stateObservable
                .asDriver(onErrorJustReturn: .initializing)
                .map {[weak self] in
                    $0 == .loaded && self?.viewModel.recipientsListViewModel.getData(type: SendToken.Recipient.self).count == 0 && self?.addressInputView.textField.text?.isEmpty == false
                }
                .map {!$0}
                .drive(noAddressView.rx.isHidden)
                .disposed(by: disposeBag)
            
            isSearchingDriver
                .skip(1)
                .drive(onNext: {[weak self] _ in
                    UIView.animate(withDuration: 0.3) {
                        self?.layoutIfNeeded()
                    }
                })
                .disposed(by: disposeBag)
            
            // address
            viewModel.recipientDriver
                .drive(onNext: {[weak self] recipient in
                    guard let recipient = recipient else {return}
                    self?.recipientView.setRecipient(recipient)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func clearRecipientButtonDidTouch() {
            viewModel.clearRecipient()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.addressInputView.textField.becomeFirstResponder()
            }
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress.RootView: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let recipient = item as? SendToken.Recipient else {return}
        viewModel.selectRecipient(recipient)
        endEditing(true)
    }
}
