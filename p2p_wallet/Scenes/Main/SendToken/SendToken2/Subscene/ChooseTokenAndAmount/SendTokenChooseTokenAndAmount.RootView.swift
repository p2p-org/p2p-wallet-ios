//
//  SendTokenChooseTokenAndAmount.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import UIKit
import RxSwift

extension SendTokenChooseTokenAndAmount {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: SendTokenChooseTokenAndAmountViewModelType
        
        // MARK: - Subviews
        private let balanceLabel = UILabel(text: "0.0", textSize: 15, weight: .medium, textColor: .textSecondary)
        private let coinLogoImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private let coinSymbolLabel = UILabel(text: "SOL", textSize: 20, weight: .semibold)
        private lazy var amountTextField: TokenAmountTextField = {
            let tf = TokenAmountTextField(
                font: .systemFont(ofSize: 27, weight: .semibold),
                textColor: .textBlack,
                textAlignment: .right,
                keyboardType: .decimalPad,
                placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
                autocorrectionType: .no
            )
            tf.delegate = self
            return tf
        }()
        private lazy var equityValueLabel = UILabel(text: "$ 0", textSize: 13)
        private lazy var actionButton = WLStepButton.main(text: L10n.chooseDestinationWallet)
        
        // MARK: - Initializer
        init(viewModel: SendTokenChooseTokenAndAmountViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
                self?.amountTextField.becomeFirstResponder()
            }
        }
        
        // MARK: - Layout
        private func layout() {
            // panel
            let panel = WLFloatingPanelView(contentInset: .init(all: 18))
            panel.stackView.axis = .vertical
            panel.stackView.alignment = .fill
            panel.stackView.addArrangedSubviews {
                UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                    UILabel(text: L10n.from, textSize: 15, weight: .medium)
                    UIView.spacer
                    UIImageView(width: 20, height: 20, image: .tabbarWallet, tintColor: .textSecondary)
                    balanceLabel
                    UILabel(text: L10n.max.uppercased(), textSize: 15, weight: .medium, textColor: .h5887ff)
                        .onTap(self, action: #selector(useAllBalance))
                }
                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                    UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                        coinLogoImageView
                            .withContentHuggingPriority(.required, for: .horizontal)
                        coinSymbolLabel
                            .withContentHuggingPriority(.required, for: .horizontal)
                        UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .a3a5ba)
                            .withContentHuggingPriority(.required, for: .horizontal)
                    }
                        .onTap(self, action: #selector(chooseWallet))
                    amountTextField
                }
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                    UIView.spacer
                    UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                        equityValueLabel
                        UIImageView(width: 20, height: 20, image: .arrowUpDown)
                    }
                        .padding(.init(x: 18, y: 8), cornerRadius: 12)
                        .border(width: 1, color: .defaultBorder)
                }
            }
            
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                panel
                UIView.spacer
                actionButton
            }
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewSafeArea(with: .init(top: 8, left: 18, bottom: 18, right: 18), excludingEdge: .bottom)
            stackView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
        }
        
        private func bind() {
            viewModel.walletDriver
                .drive(onNext: {[weak self] wallet in
                    self?.coinLogoImageView.setUp(wallet: wallet)
                    self?.coinSymbolLabel.text = wallet?.token.symbol
                })
                .disposed(by: disposeBag)
            
            // equity label
            viewModel.walletDriver
                .map {$0?.priceInCurrentFiat == nil}
                .drive(equityValueLabel.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func useAllBalance() {
            
        }
        
        @objc private func chooseWallet() {
            
        }
    }
}

extension SendTokenChooseTokenAndAmount.RootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case let amountTextField as TokenAmountTextField:
            return amountTextField.shouldChangeCharactersInRange(range, replacementString: string)
        default:
            return true
        }
    }
}
