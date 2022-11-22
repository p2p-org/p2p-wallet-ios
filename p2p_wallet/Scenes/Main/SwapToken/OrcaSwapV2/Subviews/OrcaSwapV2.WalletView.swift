//
//  OrcaSwapV2.WalletView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import AnalyticsManager
import BEPureLayout
import Combine
import Foundation
import Resolver
import SolanaSwift
import UIKit
import KeyAppUI

extension OrcaSwapV2 {
    final class WalletView: BEView {
        enum WalletType {
            case source, destination
        }

        private var subscriptions = [AnyCancellable]()
        private var viewModel: OrcaSwapV2ViewModelType
        private let type: WalletType
        @Injected private var analyticsManager: AnalyticsManager

        private lazy var balanceView = BalanceView(forAutoLayout: ())
        private lazy var iconImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var downArrow = UIImageView(width: 10, height: 8, image: .downArrow, tintColor: .a3a5ba)

        private lazy var tokenSymbolLabel = UILabel(
            text: "TOK",
            textSize: 20,
            weight: .semibold,
            textAlignment: .center
        )

        private lazy var amountTextField = TokenAmountTextField(
            font: .systemFont(ofSize: 27, weight: .bold),
            textColor: .textBlack,
            textAlignment: .right,
            keyboardType: .decimalPad,
            placeholder: "0",
            autocorrectionType: .no /* , rightView: useAllBalanceButton, rightViewMode: .always */
        )

        private lazy var questionMarkView = UIImageView(width: 20, height: 20, image: .questionMarkCircleOutlined, tintColor: Asset.Colors.night.color)
            .onTap(self, action: #selector(questionMarkDidTouch))

        init(type: WalletType, viewModel: OrcaSwapV2ViewModelType) {
            self.type = type
            self.viewModel = viewModel
            super.init(frame: .zero)
            configureForAutoLayout()

            bind()
            amountTextField.delegate = self
        }

        override func commonInit() {
            super.commonInit()
            let action: Selector = type == .source ? #selector(chooseSourceWallet) : #selector(chooseDestinationWallet)

            switch type {
            case .source:
                balanceView.maxButton.addTarget(self, action: #selector(useAllBalance), for: .touchUpInside)
            case .destination:
                balanceView.maxButton.isHidden = true
            }

            balanceView.tintColor = .h8e8e93

            let stackView = UIStackView(axis: .vertical, spacing: 13, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .equalCentering) {
                    UILabel(text: type == .source ? L10n.from : L10n.to, textSize: 15, weight: .medium)
                    balanceView
                }

                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                    iconImageView
                        .onTap(self, action: action)
                        .withContentHuggingPriority(.required, for: .horizontal)
                    tokenSymbolLabel
                        .onTap(self, action: action)
                        .withContentHuggingPriority(.required, for: .horizontal)
                    UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                        iconImageView
                        downArrow
                    }
                    .onTap(self, action: action)

                    BEStackViewSpacing(12)

                    amountTextField

                    BEStackViewSpacing(4)

                    questionMarkView
                }
            }

            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()

            // for increasing touchable area
            let chooseWalletView = UIView(forAutoLayout: ())
                .onTap(self, action: action)
            addSubview(chooseWalletView)
            chooseWalletView.autoPinEdge(.leading, to: .leading, of: iconImageView)
            chooseWalletView.autoPinEdge(.trailing, to: .trailing, of: downArrow)
            chooseWalletView.autoPinEdge(.top, to: .top, of: iconImageView, withOffset: -10)
            chooseWalletView.autoPinEdge(.bottom, to: .bottom, of: iconImageView, withOffset: 10)
        }

        func makeFirstResponder() -> Bool {
            amountTextField.becomeFirstResponder()
        }

        private func bind() {
            // subjects
            let walletPublisher: AnyPublisher<Wallet?, Never>
            let textFieldKeydownEvent: (Double) -> AnalyticsEvent
//            let equityValueLabelPublisher: AnyPublisher<String?, Never>
            let balanceTextPublisher: AnyPublisher<String?, Never>
            let outputPublisher: AnyPublisher<Double?, Never>

            switch type {
            case .source:
                walletPublisher = viewModel.sourceWalletPublisher

                textFieldKeydownEvent = { amount in
                    AmplitudeEvent.swapTokenAAmountKeydown(sum: amount)
                }

                outputPublisher = viewModel.inputAmountPublisher

                // available amount
                balanceTextPublisher = walletPublisher
                    .map { $0?.amount?.toString(maximumFractionDigits: 9) ?? "0" }
                    .eraseToAnyPublisher()

                Publishers.CombineLatest(
                    viewModel.errorPublisher
                        .map { $0 == .insufficientFunds || $0 == .inputAmountIsNotValid },
                    viewModel.isSendingMaxAmountPublisher
                )
                    .map { isErrorState, isSendingMax -> UIColor in
                        if isErrorState {
                            return .alert
                        } else if isSendingMax {
                            return .h34c759
                        } else {
                            return .h8e8e93
                        }
                    }
                    .assign(to: \.tintColor, on: balanceView)
                    .store(in: &subscriptions)
                viewModel.isSendingMaxAmountPublisher
                    .assign(to: \.isHidden, on: balanceView.maxButton)
                    .store(in: &subscriptions)

                questionMarkView.isHidden = false
                viewModel.isSendingMaxAmountPublisher
                    .map { !$0 }
                    .assign(to: \.isHidden, on: questionMarkView)
                    .store(in: &subscriptions)

            case .destination:
                walletPublisher = viewModel.destinationWalletPublisher

                textFieldKeydownEvent = { amount in
                    AmplitudeEvent.swapTokenBAmountKeydown(sum: amount)
                }

                outputPublisher = viewModel.estimatedAmountPublisher

                balanceTextPublisher = viewModel.destinationWalletPublisher
                    .map { wallet -> String? in
                        wallet?.amount?.toString(maximumFractionDigits: 9)
                    }
                    .eraseToAnyPublisher()

                questionMarkView.isHidden = true
            }

            // wallet
            walletPublisher
                .sink { [weak self] wallet in
                    self?.setUp(wallet: wallet)
                }
                .store(in: &subscriptions)

            // balance text
            balanceTextPublisher
                .assign(to: \.text, on: balanceView.balanceLabel)
                .store(in: &subscriptions)

            balanceTextPublisher.map { $0 == nil }
                .assign(to: \.isHidden, on: balanceView.walletView)
                .store(in: &subscriptions)

            // analytics
            NotificationCenter.default.publisher(
                for: UITextField.textDidEndEditingNotification,
                object: amountTextField
            )
                .compactMap { [weak self] _ in
                    self?.amountTextField.text?.double
                }
                .map(textFieldKeydownEvent)
                .sink { [weak self] event in
                    self?.analyticsManager.log(event: event)
                }
                .store(in: &subscriptions)

            NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: amountTextField)
                .filter { [weak self] _ in self?.amountTextField.isFirstResponder == true }
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    let amount = self.amountTextField.text?.double

                    if self.type == .source {
                        self.viewModel.enterInputAmount(amount)
                    } else if self.type == .destination {
                        self.viewModel.enterEstimatedAmount(amount)
                    }
                }
                .store(in: &subscriptions)

            outputPublisher
                .map { $0?.toString(maximumFractionDigits: 9, groupingSeparator: "") }
                .filter { [weak self] _ in self?.amountTextField.isFirstResponder == false }
                .assign(to: \.text, on: amountTextField)
                .store(in: &subscriptions)
        }

        private func setUp(wallet: Wallet?) {
            amountTextField.setUp(decimals: wallet?.token.decimals)
            iconImageView.setUp(token: wallet?.token, placeholder: .tokenIconPlaceholder)
            tokenSymbolLabel.text = wallet?.token.symbol ?? L10n.select
        }

        @objc private func useAllBalance() {
            amountTextField.resignFirstResponder()
            viewModel.useAllBalance()
        }

        @objc private func chooseSourceWallet() {
            viewModel.chooseSourceWallet()
        }

        @objc private func chooseDestinationWallet() {
            viewModel.chooseDestinationWallet()
        }

        @objc private func questionMarkDidTouch() {
            viewModel.showNotifications(L10n.theMaximumValueIsCalculatedBySubtractingTheTransactionFeeFromYourBalance)
        }
    }
}

// MARK: - TextField delegate

extension OrcaSwapV2.WalletView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }

    func textFieldDidBeginEditing(_: UITextField) {
        viewModel.activeInputField = type == .source ? .source : .destination
    }

    func textFieldDidEndEditing(_: UITextField) {
        viewModel.activeInputField = .none
    }
}

private extension OrcaSwapV2.WalletView {
    class BalanceView: BEView {
        private static let subviewsHeight: CGFloat = 20

        let walletView = UIImageView(width: subviewsHeight, height: subviewsHeight, image: .newWalletIcon)
        let balanceLabel = UILabel(textSize: 15, weight: .medium)
        let maxButton = UIButton(
            height: subviewsHeight,
            label: L10n.max.uppercased(),
            labelFont: .systemFont(ofSize: 15, weight: .medium),
            textColor: Asset.Colors.night.color
        )

        override var tintColor: UIColor! {
            didSet {
                self.walletView.tintColor = tintColor
                self.balanceLabel.textColor = tintColor
            }
        }

        override func commonInit() {
            super.commonInit()

            balanceLabel.autoSetDimension(.height, toSize: Self.subviewsHeight)
            let stackView = UIStackView(axis: .horizontal, spacing: 5.33, alignment: .center, distribution: .fill) {
                walletView
                balanceLabel
                maxButton
            }
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()

            walletView.isHidden = true
        }
    }
}
