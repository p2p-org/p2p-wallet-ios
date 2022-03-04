//
// Created by Giang Long Tran on 04.03.2022.
//

import Foundation
import RxSwift

extension BuyPreparing {
    class InputCryptoView: BECompositionView {
        private let disposeBag = DisposeBag()
        private let viewModel: SolanaBuyTokenSceneModel
    
        init(viewModel: SolanaBuyTokenSceneModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fillProportionally) {
                // Input
                UIStackView(axis: .vertical, alignment: .fill) {
                    UIStackView(axis: .horizontal, alignment: .center) {
                        // Label
                        UILabel(text: L10n.youGet, textSize: 17)
                        UIView.spacer
                        // Amount
                        UIImageView(width: 24, height: 24, image: .squircleSolanaIcon)
                        UIView(width: 8)
                
                        TokenAmountTextField(
                            font: .systemFont(ofSize: 27, weight: .semibold),
                            textColor: .textBlack,
                            textAlignment: .right,
                            keyboardType: .decimalPad,
                            placeholder: "0",
                            autocorrectionType: .no
                        ).setup { [weak self] view in
                            view.becomeFirstResponder()
                            view.delegate = self
                            view.text = viewModel.input.amount.toString()
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
                    UILabel(text: L10n.youPay, textSize: 17)
                    UIView.spacer
                    // Output amount
                    UIStackView(axis: .horizontal) {
                        UILabel(text: "0.00 SOL").setup { view in
                            viewModel.outputDriver.map { output in "$ \(output.amount)" }
                                .drive(view.rx.text).disposed(by: disposeBag)
                        }
                        UIImageView(image: .arrowUpDown)
                            .padding(.init(only: .left, inset: 6))
                    }.onTap { [unowned self] in viewModel.swap() }
                        .padding(.init(x: 18, y: 8))
                        .border(width: 1, color: .c7c7cc)
                        .box(cornerRadius: 12)
                }
            }
        }
    }
}

extension BuyPreparing.InputCryptoView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        switch textField {
        case let amountTextField as TokenAmountTextField:
            return amountTextField.shouldChangeCharactersInRange(range, replacementString: string)
        default:
            return true
        }
    }
}
