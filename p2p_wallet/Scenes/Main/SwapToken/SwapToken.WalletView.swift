//
//  SwapTokenItemView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import Action
import RxSwift
import RxCocoa

extension SwapToken {
    class WalletView: BEView {
        enum WalletType {
            case source, destination
        }
        
        var wallet: Wallet?
        private let disposeBag = DisposeBag()
        private let viewModel: ViewModel
        private let type: WalletType
        
        private lazy var iconImageView = CoinLogoImageView(size: 44)
            .with(
                placeholder: UIImageView(
                    width: 24,
                    height: 24,
                    image: .walletIcon,
                    tintColor: .white
                ).padding(.init(all: 10), backgroundColor: .h5887ff, cornerRadius: 12)
            )
        
        private lazy var tokenSymbolLabel = UILabel(text: "TOK", weight: .semibold, textAlignment: .center)
        
        private lazy var amountTextField = TokenAmountTextField(
            font: .systemFont(ofSize: 27, weight: .semibold),
            textColor: .textBlack,
            keyboardType: .decimalPad,
            placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
            autocorrectionType: .no/*, rightView: useAllBalanceButton, rightViewMode: .always*/
        )
        
        private lazy var equityValueLabel = UILabel(text: "≈ 0.00 \(Defaults.fiat.symbol)", weight: .semibold, textColor: .textSecondary.onDarkMode(.white))
        
        init(viewModel: ViewModel, type: WalletType) {
            self.viewModel = viewModel
            self.type = type
            super.init(frame: .zero)
            configureForAutoLayout()
            
            bind()
            amountTextField.delegate = self
            
            // FIXME: - disable input in destination wallet, re-enable later
            if type == .destination {
                amountTextField.isUserInteractionEnabled = false
            }
        }
        
        override func commonInit() {
            super.commonInit()
            let action: Selector = type == .source ? #selector(ViewModel.chooseSourceWallet): #selector(ViewModel.chooseDestinationWallet)
            
            let stackView = UIStackView(axis: .vertical, spacing: 6, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                    
                    UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                        iconImageView
                        UIImageView(width: 11, height: 8, image: .downArrow, tintColor: .a3a5ba)
                    }
                        .onTap(viewModel, action: action)
                    
                    amountTextField
                }
                
                UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill) {
                    tokenSymbolLabel
                        .withContentHuggingPriority(.required, for: .horizontal)
                    UIView.spacer
                    equityValueLabel
                }
            }
            
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
                // wallet
                viewModel.output.sourceWallet
                    .drive(onNext: {[weak self] wallet in
                        self?.setUp(wallet: wallet)
                    })
                    .disposed(by: disposeBag)
                
                // text field
                amountTextField.rx.text
                    .bind(to: viewModel.input.amount)
                    .disposed(by: disposeBag)
                
                amountTextField.rx.controlEvent([.editingDidEnd])
                    .asObservable()
                    .subscribe(onNext: { [weak self] _ in
                        guard let amount = self?.amountTextField.text?.double else {return}
                        self?.viewModel.analyticsManager.log(event: .swapTokenAAmountKeydown(sum: amount))
                    })
                    .disposed(by: disposeBag)
                
                viewModel.output.useAllBalanceDidTap
                    .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                    .drive(onNext: {[weak self] in
                        // write text without notifying
                        self?.amountTextField.text = $0
                    })
                    .disposed(by: disposeBag)
                
                // FIXME: - BiBinding
                //                viewModel.output.amount
                //                    .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                //                    .drive(amountTextField.rx.text)
                //                    .disposed(by: disposeBag)
                
                // equity value label
                // FIXME: - price observing
                Driver.combineLatest(
                    viewModel.output.amount,
                    viewModel.output.sourceWallet
                )
                    .map {amount, wallet in
                        if let wallet = wallet {
                            let value = amount * wallet.priceInCurrentFiat
                            return "≈ \(value.toString(maximumFractionDigits: 9)) \(Defaults.fiat.symbol)"
                        } else {
                            return L10n.selectCurrency
                        }
                    }
                    .drive(equityValueLabel.rx.text)
                    .disposed(by: disposeBag)
                
            case .destination:
                // wallet
                viewModel.output.destinationWallet
                    .drive(onNext: { [weak self] wallet in
                        self?.setUp(wallet: wallet)
                    })
                    .disposed(by: disposeBag)
                
                // textField
//                amountTextField.rx.text
//                    .bind(to: viewModel.input.estimatedAmount)
//                    .disposed(by: disposeBag)
                
//                amountTextField.rx.controlEvent([.editingDidEnd])
//                    .asObservable()
//                    .subscribe(onNext: { [weak self] _ in
//                        guard let amount = self?.amountTextField.text?.double else {return}
//                        self?.viewModel.analyticsManager.log(event: .swapTokenBAmountKeydown, params: ["sum": amount])
//                    })
//                    .disposed(by: disposeBag)
                
                viewModel.output.estimatedAmount
                    .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                    .drive(amountTextField.rx.text)
                    .disposed(by: disposeBag)
                
                // equity value label
                viewModel.output.destinationWallet
                    .map {destinationWallet -> String? in
                        if destinationWallet != nil {
                            return nil
                        } else {
                            return L10n.selectCurrency
                        }
                    }
                    .drive(equityValueLabel.rx.text)
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
