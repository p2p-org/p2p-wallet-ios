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
import SolanaSwift

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
        private lazy var feeView = FeeView(viewModel: viewModel)
        
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
                BEStackViewSpacing(18)
                feeView
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
            
            // address input view
            isSearchingDriver.map {!$0}
                .drive(addressInputView.rx.isHidden)
                .disposed(by: disposeBag)
            
            // recipient view
            isSearchingDriver
                .drive(recipientView.rx.isHidden)
                .disposed(by: disposeBag)
            
            // searching empty state
            let shouldHideNetworkDriver: Driver<Bool>
            if viewModel.preSelectedNetwork == nil {
                shouldHideNetworkDriver = isSearchingDriver
            } else {
                // show preselected network when search is empty
                shouldHideNetworkDriver = Driver.combineLatest(
                    isSearchingDriver.map {!$0},
                    viewModel.searchTextDriver.map {$0 == nil || $0?.isEmpty == true}
                )
                .map {$0.1 || $0.0}
                .map {!$0}
            }
            
            // collection view
            shouldHideNetworkDriver.map {!$0}
                .drive(recipientCollectionView.rx.isHidden)
                .disposed(by: disposeBag)
            
            // net work view
            shouldHideNetworkDriver
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
            
            // fee view
            isSearchingDriver
                .drive(feeView.rx.isHidden)
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
            guard viewModel.preSelectedNetwork == nil else {return}
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
    
    private class FeeView: WLFloatingPanelView {
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        private let disposeBag = DisposeBag()
        private let coinLogoImageView = CoinLogoImageView(size: 44)
        
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(contentInset: .init(all: 18))
            stackView.alignment = .center
            stackView.axis = .horizontal
            stackView.spacing = 12
            stackView.addArrangedSubviews {
                coinLogoImageView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    UILabel(text: "Account creation fee", textSize: 13, numberOfLines: 0)
                        .setup { label in
                            self.viewModel.feesDriver
                                .map {feeAmountToAttributedString(feeAmount: $0)}
                                .drive(label.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                    UILabel(text: "0.509 USDC", textSize: 17, weight: .semibold)
                }
                UIView.defaultNextArrow()
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

private func feeAmountToAttributedString(feeAmount: SolanaSDK.FeeAmount) -> NSAttributedString {
    var attributedString = [NSMutableAttributedString]()
    if feeAmount.accountBalances > 0 {
        attributedString.append(
            NSMutableAttributedString()
                .text(L10n.accountCreationFee, size: 13, color: .textSecondary)
                .text(" ")
                .text(feeAmount.accountBalances.convertToBalance(decimals: 9).toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true), size: 13)
                .text(" SOL", size: 13)
        )
    }
    
    if feeAmount.transaction > 0 {
        attributedString.append(
            NSMutableAttributedString()
                .text(L10n.transactionFee, size: 13, color: .textSecondary)
                .text(" ")
                .text(feeAmount.transaction.convertToBalance(decimals: 9).toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true), size: 13)
                .text(" SOL", size: 13)
        )
    }
    
    if attributedString.count == 2 {
        attributedString.insert(NSMutableAttributedString().text(", "), at: 1)
    }
    
    return attributedString.reduce(NSMutableAttributedString(), {result, attributedString in
        result.append(attributedString)
        return result
    })
}
