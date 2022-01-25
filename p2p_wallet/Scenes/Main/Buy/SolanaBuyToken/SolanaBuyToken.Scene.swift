//
//  SolanaBuyToken.Scene.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation
import RxCocoa

extension SolanaBuyToken {
    class Scene: BEScene {
        private let viewModel: SolanaBuyTokenSceneModel
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        init(viewModel: SolanaBuyTokenSceneModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func build() -> UIView {
            BEZStack {
                // Content
                content().withTag(1)
                // Bottom Button
                WLStepButton.main(text: L10n.continue)
                    .setup { view in
                        guard let view = view as? WLStepButton else { return }
                        viewModel.nextStatus.map { $0.text }.drive(view.rx.text).disposed(by: disposeBag)
                        viewModel.nextStatus.map { $0.isEnable }.drive(view.rx.isEnabled).disposed(by: disposeBag)
                    }
                    .onTap { [unowned self] in viewModel.next() }
                    .padding(.init(all: 18))
                    .withTag(2)
            }.setup { view in
                view.viewWithTag(1)?.autoPinEdgesToSuperviewSafeArea()
                
                view.viewWithTag(2)?.autoPinBottomToSuperViewAvoidKeyboard()
                view.viewWithTag(2)?.autoPinEdge(toSuperviewEdge: .leading)
                view.viewWithTag(2)?.autoPinEdge(toSuperviewEdge: .trailing)
            }.onTap { [unowned self] in
                // dismiss keyboard
                view.endEditing(true)
            }
        }
        
        private func content() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                NewWLNavigationBar(initialTitle: L10n.buyOnMoonpay("ETH"))
                    .onBack { [unowned self] in self.viewModel.back() }
                
                BEScrollView(contentInsets: .init(top: 18, left: 18, bottom: 90, right: 18), spacing: 18) {
                    // Exchange
                    UIStackView(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fillProportionally) {
                        // Input
                        UIStackView(axis: .vertical, alignment: .fill) {
                            UIStackView(axis: .horizontal, alignment: .bottom) {
                                // Label
                                UILabel(text: L10n.youPay, textSize: 17)
                                UIView.spacer
                                // Amount
                                UILabel(
                                    text: "$",
                                    font: .systemFont(ofSize: 27, weight: .semibold),
                                    textColor: .textBlack
                                ).padding(.init(x: 4, y: 0))
                                TokenAmountTextField(
                                    font: .systemFont(ofSize: 27, weight: .semibold),
                                    textColor: .textBlack,
                                    textAlignment: .right,
                                    keyboardType: .decimalPad,
                                    placeholder: "0\(Locale.current.decimalSeparator ?? ".")0",
                                    autocorrectionType: .no
                                ).setup { [weak self] view in
                                    view.delegate = self
                                    view.rx.text
                                        .map { $0?.double }
                                        .distinctUntilChanged()
                                        .subscribe(onNext: { [weak self] amount in
                                            guard let amount = amount else { return }
                                            self?.viewModel.setAmount(value: amount)
                                        })
                                        .disposed(by: disposeBag)
                                }
                            }
                        }
                        
                        UIView.defaultSeparator()
                        
                        // Output
                        UIStackView(axis: .horizontal, alignment: .center) {
                            // Label
                            UILabel(text: L10n.youGet, textSize: 17)
                            UIView.spacer
                            // Output amount
                            UIStackView(axis: .horizontal) {
                                UILabel(text: "0.00 ETH").setup { view in
                                    self.viewModel.quoteAmount.map { value in "\(value) ETH" }
                                        .drive(view.rx.text).disposed(by: disposeBag)
                                }
                                UIImageView(image: .arrowUpDown)
                                    .padding(.init(only: .left, inset: 6))
                            }.padding(.init(x: 18, y: 8))
                                .border(width: 1, color: .c7c7cc)
                                .box(cornerRadius: 12)
                        }
                        
                    }.frame(height: 148)
                        .padding(.init(all: 18))
                        .border(width: 1, color: .f2f2f7)
                        .box(cornerRadius: 12)
                        .lightShadow()
                    
                    // Description
                    UIStackView(axis: .vertical, spacing: 8, alignment: .fill) {
                        UILabel(text: "Moonpay", weight: .bold)
                        UIView.defaultSeparator()
                        
                        descriptionRow(label: "ETH Price", initial: "$ 0.0", viewModel.solanaPrice.map { "$ \($0)" })
                        descriptionRow(label: L10n.processingFee, initial: "$ 0.00", viewModel.feeAmount.map { "$ \($0)" })
                        descriptionRow(label: L10n.networkFee, initial: "$ 0.00", viewModel.networkFee.map { "$ \($0)" })
                        descriptionRow(label: L10n.total, initial: "$ 0.00", viewModel.total.map { "$ \($0)" })
                    }.padding(.init(all: 18))
                }
                
            }
        }
        
        private func descriptionRow(label: String, initial: String, _ trailingDriver: Driver<String>? = nil) -> UIView {
            UIStackView(axis: .horizontal, alignment: .fill) {
                UILabel(text: label, textColor: .secondaryLabel)
                UIView.spacer
                UILabel(text: initial).setup { view in
                    trailingDriver?.drive(view.rx.text).disposed(by: disposeBag)
                }
            }
        }
    }
}

extension SolanaBuyToken.Scene: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case let amountTextField as TokenAmountTextField:
            return amountTextField.shouldChangeCharactersInRange(range, replacementString: string)
        default:
            return true
        }
    }
}
