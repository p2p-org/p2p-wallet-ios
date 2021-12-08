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
        private lazy var networkView = _NetworkView(viewModel: viewModel)
            .onTap(self, action: #selector(networkViewDidTouch))
        private lazy var errorView = UIStackView(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill) {
            UIImageView(width: 44, height: 44, image: .errorUserAvatar)
            errorLabel
        }
            .padding(.init(x: 20, y: 0))
        private lazy var errorLabel = UILabel(text: L10n.thereSNoAddressLikeThis, textSize: 17, textColor: .ff3b30, numberOfLines: 0)
        
        private lazy var actionButton = WLStepButton.main(text: L10n.chooseTheRecipientToProceed)
            .onTap(self, action: #selector(actionButtonDidTouch))
        
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
            scrollView.contentInset.modify(dTop: -.defaultPadding, dBottom: 56 + 18)
            stackView.addArrangedSubviews {
                UIView.floatingPanel {
                    titleView
                    BEStackViewSpacing(20)
                    addressInputView
                    recipientView
                }
                BEStackViewSpacing(18)
                networkView
                errorView
                recipientCollectionView
            }
            
            addSubview(actionButton)
            actionButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 18)
            actionButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 18)
            actionButton.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 18)
            
            recipientCollectionView.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -(56 + 18))
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
                .drive(onNext: {[weak self] state in
                    var shouldHideErrorView = true
                    var errorText = L10n.thereIsAnErrorOccurredPleaseTryAgain
                    switch state {
                    case .initializing, .loading:
                        break
                    case .loaded:
                        if self?.viewModel.recipientsListViewModel.getData(type: SendToken.Recipient.self).count == 0 && self?.addressInputView.textField.text?.isEmpty == false
                        {
                            shouldHideErrorView = false
                            errorText = L10n.thereSNoAddressLikeThis
                        }
                    case .error:
                        shouldHideErrorView = false
                    }
                    self?.errorView.isHidden = shouldHideErrorView
                    self?.errorLabel.text = errorText
                })
                .disposed(by: disposeBag)
            
            viewModel.inputStateDriver
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
                    self?.recipientView.setHighlighted()
                })
                .disposed(by: disposeBag)
            
            // action button
            viewModel.isValidDriver
                .drive(actionButton.rx.isEnabled)
                .disposed(by: disposeBag)
            
            viewModel.isValidDriver
                .map {$0 ? UIImage.buttonCheckSmall: nil}
                .drive(actionButton.rx.image)
                .disposed(by: disposeBag)
            
            viewModel.isValidDriver
                .map {$0 ? L10n.reviewAndConfirm: L10n.chooseTheRecipientToProceed}
                .drive(actionButton.rx.text)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func clearRecipientButtonDidTouch() {
            viewModel.clearRecipient()
            viewModel.clearSearching()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.addressInputView.textField.becomeFirstResponder()
            }
        }
        
        @objc private func networkViewDidTouch() {
            viewModel.navigateToChoosingNetworkScene()
        }
        
        @objc private func actionButtonDidTouch() {
            viewModel.next()
        }
    }
    
    private class _NetworkView: WLFloatingPanelView {
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        private let _networkView = SendToken.NetworkView()
        private let disposeBag = DisposeBag()
        
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(contentInset: .init(all: 18))
            _networkView.addArrangedSubview(UIView.defaultNextArrow())
            stackView.addArrangedSubview(_networkView)
            bind()
        }
        
        private func bind() {
            viewModel.networkDriver
                .drive(onNext: {[weak self] network in
                    self?._networkView.setUp(
                        network: network,
                        prices: self?.viewModel.getSOLAndRenBTCPrices() ?? [:]
                    )
                })
                .disposed(by: disposeBag)
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
