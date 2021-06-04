//
//  SwapTokenItemView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import Action
import RxSwift

extension SwapToken {
    class WalletView: BEView {
        enum WalletType {
            case source, destination
        }
        
        var wallet: Wallet?
        let disposeBag = DisposeBag()
        let viewModel: ViewModel
        let type: WalletType
        
        lazy var iconImageView = CoinLogoImageView(size: 44)
            .with(
                placeholder: UIImageView(
                    width: 24,
                    height: 24,
                    image: .walletIcon,
                    tintColor: .white
                ).padding(.init(all: 10), backgroundColor: .h5887ff, cornerRadius: 12)
            )
        
        lazy var tokenSymbolLabel = UILabel(text: "TOK", weight: .semibold, textAlignment: .center)
        
        private lazy var amountTextField = TokenAmountTextField(
            font: .systemFont(ofSize: 27, weight: .semibold),
            textColor: .textBlack,
            keyboardType: .decimalPad,
            placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
            autocorrectionType: .no/*, rightView: useAllBalanceButton, rightViewMode: .always*/
        )
        
        lazy var equityValueLabel = UILabel(text: "≈ 0.00 \(Defaults.fiat.symbol)", weight: .semibold, textColor: .textSecondary)
        
        init(viewModel: ViewModel, type: WalletType) {
            self.viewModel = viewModel
            self.type = type
            super.init(frame: .zero)
            configureForAutoLayout()
            bind()
            amountTextField.delegate = self
        }
        
        override func commonInit() {
            super.commonInit()
            let action: Selector = type == .source ? #selector(ViewModel.chooseSourceWallet): #selector(ViewModel.chooseDestinationWallet)
            
            let stackView = UIStackView(axis: .vertical, spacing: 6, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                    iconImageView
                        .onTap(viewModel, action: action),
                    UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .a3a5ba)
                        .onTap(viewModel, action: action),
                    amountTextField
                ]),
                UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
                    tokenSymbolLabel
                        .withContentHuggingPriority(.required, for: .horizontal),
                    UIView.spacer,
                    equityValueLabel
                ])
            ])
            
            tokenSymbolLabel.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor)
                .isActive = true
            tokenSymbolLabel.adjustsFontSizeToFitWidth = true
            equityValueLabel.leadingAnchor.constraint(equalTo: amountTextField.leadingAnchor)
                .isActive = true
            
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
        }
        
        private func bind() {
            // textFields
            switch type {
            case .source:
                amountTextField.rx.text
                    .bind(to: viewModel.input.amount)
                    .disposed(by: disposeBag)
                
                viewModel.output.sourceWallet
                    .drive(onNext: {[weak self] wallet in
                        self?.setUp(wallet: wallet)
                    })
                    .disposed(by: disposeBag)
                
                viewModel.output.amount
                    .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                    .drive(amountTextField.rx.text)
                    .disposed(by: disposeBag)
                
                viewModel.output.useAllBalanceDidTap
                    .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                    .drive(onNext: {[weak self] in
                        // write text without notifying
                        self?.amountTextField.text = $0
                    })
                    .disposed(by: disposeBag)
                
            case .destination:
                amountTextField.rx.text
                    .bind(to: viewModel.input.estimatedAmount)
                    .disposed(by: disposeBag)
                
                viewModel.output.destinationWallet
                    .drive(onNext: { [weak self] wallet in
                        self?.setUp(wallet: wallet)
                    })
                    .disposed(by: disposeBag)
                
                viewModel.output.estimatedAmount
                    .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                    .drive(amountTextField.rx.text)
                    .disposed(by: disposeBag)
            }
        }
        
        private func setUp(wallet: Wallet?) {
            amountTextField.wallet = wallet
            iconImageView.setUp(wallet: wallet)
            if let wallet = wallet {
                tokenSymbolLabel.alpha = 1
                tokenSymbolLabel.text = wallet.token.symbol
            } else {
                tokenSymbolLabel.alpha = 0
                tokenSymbolLabel.text = nil
            }
            
            self.wallet = wallet
        }
    }
}

// MARK: - TextField delegate
extension SwapToken.WalletView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
