//
//  OrcaSwapV2.WalletView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import Action
import RxSwift
import RxCocoa

extension OrcaSwapV2 {
    final class WalletView: BEView {
        enum WalletType {
            case source, destination
        }
        
        var wallet: Wallet?
        private let disposeBag = DisposeBag()
        private let viewModel: OrcaSwapV2ViewModelType
        private let type: WalletType
        @Injected private var analyticsManager: AnalyticsManagerType
        
        private lazy var balanceView = BalanceView(forAutoLayout: ())
        private lazy var iconImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var downArrow = UIImageView(width: 10, height: 8, image: .downArrow, tintColor: .a3a5ba)
        
        private lazy var tokenSymbolLabel = UILabel(text: "TOK", weight: .semibold, textAlignment: .center)

        private lazy var amountTextField = TokenAmountTextField(
            font: .systemFont(ofSize: 27, weight: .bold),
            textColor: .textBlack,
            textAlignment: .right,
            keyboardType: .decimalPad,
            placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
            autocorrectionType: .no/*, rightView: useAllBalanceButton, rightViewMode: .always*/
        )

        init(viewModel: OrcaSwapV2ViewModelType, type: WalletType) {
            self.viewModel = viewModel
            self.type = type
            super.init(frame: .zero)
            configureForAutoLayout()
            
            bind()
            amountTextField.delegate = self
        }
        
        override func commonInit() {
            super.commonInit()
            let action: Selector = type == .source ? #selector(chooseSourceWallet): #selector(chooseDestinationWallet)
            let balanceView = type == .destination ? balanceView: balanceView
                .onTap(self, action: #selector(useAllBalance))
            balanceView.tintColor = type == .source ? .h5887ff: .textSecondary.onDarkMode(.white)
            
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
        
        private func bind() {
            // subjects
            let walletDriver: Driver<Wallet?>
            let textFieldKeydownEvent: (Double) -> AnalyticsEvent
//            let equityValueLabelDriver: Driver<String?>
            let balanceTextDriver: Driver<String?>
            let outputDriver: Driver<Double?>
            
            switch type {
            case .source:
                walletDriver = viewModel.sourceWalletDriver
                
                textFieldKeydownEvent = {amount in
                    .swapTokenAAmountKeydown(sum: amount)
                }
                
//                equityValueLabelDriver = Driver.combineLatest(
//                    viewModel.inputAmountDriver,
//                    viewModel.sourceWalletDriver
//                )
//                    .map {amount, wallet in
//                        if let wallet = wallet {
//                            let value = amount * wallet.priceInCurrentFiat
//                            return "≈ \(value.toString(maximumFractionDigits: 9)) \(Defaults.fiat.symbol)"
//                        } else {
//                            return L10n.selectCurrency
//                        }
//                    }
                
                outputDriver = viewModel.inputAmountDriver
                
                // available amount
                balanceTextDriver = viewModel.availableAmountDriver
                    .withLatestFrom(viewModel.sourceWalletDriver, resultSelector: { ($0, $1) })
                    .map {amount, wallet -> String? in
                        guard let amount = amount else {return nil}
                        return amount.toString(maximumFractionDigits: 9) + " " + wallet?.token.symbol
                    }
                
                viewModel.errorDriver
                    .map {$0 == .insufficientFunds || $0 == .inputAmountIsNotValid}
                    .map {$0 ? UIColor.alert: UIColor.h5887ff}
                    .drive(balanceView.rx.tintColor)
                    .disposed(by: disposeBag)
                                
            case .destination:
                walletDriver = viewModel.destinationWalletDriver
                
                textFieldKeydownEvent = {amount in
                    .swapTokenBAmountKeydown(sum: amount)
                }
                
//                equityValueLabelDriver = viewModel.minimumReceiveAmountDriver
//                    .withLatestFrom(viewModel.destinationWalletDriver, resultSelector: {($0, $1)})
//                    .map {minReceiveAmount, wallet -> String? in
//                        guard let symbol = wallet?.token.symbol else {return nil}
//                        return L10n.receiveAtLeast + ": " + minReceiveAmount?.toString(maximumFractionDigits: 9) + " " + symbol
//                    }
                
                outputDriver = viewModel.estimatedAmountDriver
                
                balanceTextDriver = viewModel.destinationWalletDriver
                    .map { wallet -> String? in
                        if let amount = wallet?.amount?.toString(maximumFractionDigits: 9) {
                            return amount + " " + "\(wallet?.token.symbol ?? "")"
                        }
                        return nil
                    }
            }
            
            // wallet
            walletDriver
                .drive(onNext: { [weak self] wallet in
                    self?.setUp(wallet: wallet)
                })
                .disposed(by: disposeBag)
            
            // balance text
            balanceTextDriver
                .drive(balanceView.balanceLabel.rx.text)
                .disposed(by: disposeBag)
            
            balanceTextDriver.map {$0 == nil}
                .drive(balanceView.walletView.rx.isHidden)
                .disposed(by: disposeBag)
            
            // analytics
            amountTextField.rx.controlEvent([.editingDidEnd])
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    guard let amount = self?.amountTextField.text?.double else {return}
                    let event = textFieldKeydownEvent(amount)
                    self?.analyticsManager.log(event: event)
                })
                .disposed(by: disposeBag)
            
            // equity value label
//            equityValueLabelDriver
//                .drive(equityValueLabel.rx.text)
//                .disposed(by: disposeBag)
            
            amountTextField.rx.text
                .filter {[weak self] _ in self?.amountTextField.isFirstResponder == true}
                .distinctUntilChanged()
                .map {$0?.double}
                .subscribe(onNext: {[weak self] double in
                    if self?.type == .source {
                        self?.viewModel.enterInputAmount(double)
                    } else if self?.type == .destination {
                        self?.viewModel.enterEstimatedAmount(double)
                    }
                })
                .disposed(by: disposeBag)
            
            outputDriver
                .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                .filter {[weak self] _ in self?.amountTextField.isFirstResponder == false}
                .drive(amountTextField.rx.text)
                .disposed(by: disposeBag)
        }
        
        private func setUp(wallet: Wallet?) {
            amountTextField.wallet = wallet
            iconImageView.setUp(token: wallet?.token, placeholder: .walletPlaceholder)
            tokenSymbolLabel.text = wallet?.token.symbol ?? L10n.select
            
            self.wallet = wallet
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
    }
}

// MARK: - TextField delegate
extension OrcaSwapV2.WalletView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}

private extension OrcaSwapV2.WalletView {
    class BalanceView: BEView {
        private let disposeBag = DisposeBag()
        lazy var walletView = UIImageView(width: 16, height: 16, image: .walletIcon)
        lazy var balanceLabel = UILabel(textSize: 13, weight: .medium)
        
        override var tintColor: UIColor! {
            didSet {
                self.walletView.tintColor = tintColor
                self.balanceLabel.textColor = tintColor
            }
        }
        
        override func commonInit() {
            super.commonInit()
            let stackView = UIStackView(axis: .horizontal, spacing: 5.33, alignment: .center, distribution: .fill) {
                walletView
                balanceLabel
            }
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
            
            walletView.isHidden = true
        }
    }
}
