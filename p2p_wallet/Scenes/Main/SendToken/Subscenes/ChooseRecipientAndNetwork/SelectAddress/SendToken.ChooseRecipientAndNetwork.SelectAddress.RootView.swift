//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/11/2021.
//

import BECollectionView
import BEPureLayout
import RxCocoa
import RxSwift
import SolanaSwift
import UIKit

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
        private lazy var errorView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            distribution: .fill
        ) {
            UIImageView(width: 44, height: 44, image: .errorUserAvatar)
            errorLabel
        }
        .padding(.init(x: 20, y: 0))
        private lazy var warningView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            distribution: .fill
        ) {
            UIImageView(width: 44, height: 44, image: .warningUserAvatar)
            warningLabel
        }

        private lazy var errorLabel = UILabel(
            text: L10n.thereSNoAddressLikeThis,
            textSize: 17,
            textColor: .ff3b30,
            numberOfLines: 0
        )
        private lazy var warningLabel = UILabel(
            textSize: 13,
            textColor: .ff9500,
            numberOfLines: 0
        )
        private lazy var feeView = _FeeView( // for relayMethod == .relay only
            walletDriver: viewModel.walletDriver,
            solPrice: viewModel.getPrice(for: "SOL"),
            feeInfoDriver: viewModel.feeInfoDriver,
            payingWalletDriver: viewModel.payingWalletDriver
        )
            .onTap { [weak self] in
                self?.viewModel.navigate(to: .selectPayingWallet)
            }

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
                if viewModel.relayMethod == .relay {
                    feeView
                }
                warningView
                #if DEBUG
                    UILabel(textColor: .red, numberOfLines: 0, textAlignment: .center)
                        .setup { label in
                            viewModel.feeInfoDriver
                                .map { $0.value?.feeAmountInSOL ?? .zero }
                                .drive(onNext: { [weak label] feeAmount in
                                    label?.attributedText = NSMutableAttributedString()
                                        .text(
                                            "Transaction fee: \(feeAmount.transaction) lamports",
                                            size: 13,
                                            color: .red
                                        )
                                        .text(", ")
                                        .text(
                                            "Account creation fee: \(feeAmount.accountBalances) lamports",
                                            size: 13,
                                            color: .red
                                        )
                                })
                                .disposed(by: disposeBag)
                        }
                #endif
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
                .map { $0 == .searching }
                .distinctUntilChanged()

            // address input view
            isSearchingDriver.map { !$0 }
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
                    isSearchingDriver.map { !$0 },
                    viewModel.searchTextDriver.map { $0 == nil || $0?.isEmpty == true }
                )
                    .map { $0.1 || $0.0 }
                    .map { !$0 }
            }

            // collection view
            shouldHideNetworkDriver.map { !$0 }
                .drive(recipientCollectionView.rx.isHidden)
                .disposed(by: disposeBag)

            // net work view
            shouldHideNetworkDriver
                .drive(networkView.rx.isHidden)
                .disposed(by: disposeBag)

            viewModel.recipientsListViewModel
                .stateObservable
                .asDriver(onErrorJustReturn: .initializing)
                .drive(onNext: { [weak self] state in
                    var shouldHideErrorView = true
                    var errorText = L10n.thereIsAnErrorOccurredPleaseTryAgain
                    switch state {
                    case .initializing, .loading:
                        break
                    case .loaded:
                        if self?.viewModel.recipientsListViewModel.getData(type: SendToken.Recipient.self)
                            .isEmpty == true, self?.addressInputView.textField.text?.isEmpty == false
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
            Driver.combineLatest(
                isSearchingDriver,
                viewModel.networkDriver,
                viewModel.feeInfoDriver
            )
                .map { isSearching, network, fee in
                    if isSearching || network != .solana {
                        return true
                    }
                    if let fee = fee.value?.feeAmountInSOL {
                        return fee.total == 0
                    } else {
                        return true
                    }
                }
                .drive(feeView.rx.isHidden)
                .disposed(by: disposeBag)

            viewModel.inputStateDriver
                .skip(1)
                .drive(onNext: { [weak self] _ in
                    UIView.animate(withDuration: 0.3) {
                        self?.layoutIfNeeded()
                    }
                })
                .disposed(by: disposeBag)

            // address
            viewModel.recipientDriver
                .drive(onNext: { [weak self] recipient in
                    guard let recipient = recipient else { return }
                    self?.recipientView.setRecipient(recipient)
                    self?.recipientView.setHighlighted()
                })
                .disposed(by: disposeBag)

            // action button
            viewModel.isValidDriver
                .drive(actionButton.rx.isEnabled)
                .disposed(by: disposeBag)

            viewModel.isValidDriver
                .map { $0 ? UIImage.buttonCheckSmall : nil }
                .drive(actionButton.rx.image)
                .disposed(by: disposeBag)

            Driver.combineLatest(
                viewModel.walletDriver,
                viewModel.recipientDriver,
                viewModel.payingWalletDriver,
                viewModel.feeInfoDriver,
                viewModel.networkDriver
            )
                .map { [weak self] sourceWallet, recipient, payingWallet, feeInfo, network in
                    guard let self = self else { return "" }
                    if recipient == nil {
                        return L10n.chooseTheRecipientToProceed
                    }

                    switch network {
                    case .solana:
                        switch self.viewModel.relayMethod {
                        case .relay:
                            switch feeInfo.state {
                            case .notRequested:
                                return L10n.chooseTheTokenToPayFees
                            case .loading:
                                return L10n.calculatingFees
                            case .loaded:
                                guard let value = feeInfo.value else {
                                    return L10n.PayingTokenIsNotValid.pleaseChooseAnotherOne
                                }
                                if value.hasAvailableWalletToPayFee == false {
                                    return L10n.insufficientFundsToCoverFees
                                }
                                if value.feeAmount.total > 0,
                                   let payingWallet = payingWallet,
                                   let lamports = payingWallet.lamports
                                {
                                    if lamports < value.feeAmount.total {
                                        let neededAmount = value.feeAmount.total
                                            .convertToBalance(decimals: payingWallet.token.decimals)
                                            .toString(maximumFractionDigits: Int(payingWallet.token.decimals))
                                        return L10n.yourAccountDoesNotHaveEnoughToCoverFees(payingWallet.token.symbol)
                                            + ". "
                                            + L10n.needsAtLeast(neededAmount + " \(payingWallet.token.symbol)")
                                    }

                                    if lamports == value.feeAmount.total, sourceWallet?.pubkey == payingWallet.pubkey {
                                        return L10n.yourAccountDoesNotHaveEnoughToCoverFees(payingWallet.token.symbol)
                                    }
                                }
                                if value.feeAmount.total == 0, value.feeAmountInSOL.total > 0 {
                                    return L10n.PayingTokenIsNotValid.pleaseChooseAnotherOne
                                }
                            case .error:
                                return L10n.PayingTokenIsNotValid.pleaseChooseAnotherOne
                            }
                        case .reward:
                            break
                        }
                    case .bitcoin:
                        break
                    }

                    return L10n.reviewAndConfirm
                }
                .drive(actionButton.rx.text)
                .disposed(by: disposeBag)

            viewModel.warningDriver
                .drive(warningLabel.rx.text)
                .disposed(by: disposeBag)
            viewModel.warningDriver
                .map { ($0 ?? "").isEmpty }
                .drive(warningView.rx.isHidden)
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
            guard viewModel.preSelectedNetwork == nil else { return }
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
            super.init(cornerRadius: 12, contentInset: .init(all: 18))
            _networkView.addArrangedSubview(UIView.defaultNextArrow())
            stackView.addArrangedSubview(_networkView)
            bind()
        }

        private func bind() {
            Driver.combineLatest(
                viewModel.networkDriver,
                viewModel.payingWalletDriver,
                viewModel.feeInfoDriver
            )
                .drive(onNext: { [weak self] network, payingWallet, feeInfo in
                    self?._networkView.setUp(
                        network: network,
                        payingWallet: payingWallet,
                        feeInfo: feeInfo.value,
                        prices: self?.viewModel.getPrices(for: ["SOL", "renBTC"]) ?? [:]
                    )
                })
                .disposed(by: disposeBag)
        }
    }
}

extension SendToken.ChooseRecipientAndNetwork.SelectAddress.RootView: BECollectionViewDelegate {
    func beCollectionView(collectionView _: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let recipient = item as? SendToken.Recipient else { return }
        viewModel.selectRecipient(recipient)
        endEditing(true)
    }
}

private class _FeeView: UIStackView {
    private let disposeBag = DisposeBag()
    private let feeView: SendToken.FeeView
    private let attentionLabel = UILabel(
        text: nil,
        textSize: 15,
        numberOfLines: 0
    )

    init(
        walletDriver: Driver<Wallet?>,
        solPrice: Double,
        feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>>,
        payingWalletDriver: Driver<Wallet?>
    ) {
        feeView = .init(solPrice: solPrice, payingWalletDriver: payingWalletDriver, feeInfoDriver: feeInfoDriver)
        super.init(frame: .zero)
        set(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
        addArrangedSubviews {
            attentionLabel
                .padding(
                    .init(all: 18),
                    backgroundColor: .fffaf2.onDarkMode(.a3a5ba.withAlphaComponent(0.05)),
                    cornerRadius: 12,
                    borderColor: .ff9500
                )
            feeView
        }

        feeInfoDriver
            .map { $0.value?.feeAmountInSOL }
            .map { $0?.accountBalances ?? 0 == 0 }
            .drive(attentionLabel.superview!.rx.isHidden)
            .disposed(by: disposeBag)

        walletDriver.map { $0?.token.symbol ?? "" }
            .map {
                L10n.ThisAddressDoesNotAppearToHaveAAccount.YouHaveToPayAOneTimeFeeToCreateAAccountForThisAddress
                    .youCanChooseWhichCurrencyToPayInBelow(
                        $0,
                        $0
                    )
            }
            .drive(attentionLabel.rx.text)
            .disposed(by: disposeBag)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
