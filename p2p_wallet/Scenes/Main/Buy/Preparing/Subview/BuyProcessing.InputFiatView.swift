//
// Created by Giang Long Tran on 04.03.2022.
//

import Combine
import CombineCocoa
import Foundation
import Resolver
import SolanaSwift

extension BuyPreparing {
    class InputFiatView: BECompositionView {
        private var subscriptions = [AnyCancellable]()
        private let viewModel: BuyPreparingSceneModel

        init(viewModel: BuyPreparingSceneModel) {
            self.viewModel = viewModel
            super.init()
        }

        override func build() -> UIView {
            UIStackView(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fillProportionally) {
                // Input
                UIStackView(axis: .vertical, alignment: .fill) {
                    UIStackView(axis: .horizontal, alignment: .center) {
                        // Label
                        UILabel(text: L10n.youPay, textSize: 17)
                        UIView.spacer
                        // Amount
                        UILabel(
                            text: "$",
                            font: .systemFont(ofSize: 27, weight: .semibold),
                            textColor: .textBlack
                        ).padding(.init(x: 4, y: 0))
                        UITextField(
                            font: .systemFont(ofSize: 27, weight: .semibold),
                            textColor: .textBlack,
                            textAlignment: .right,
                            keyboardType: .decimalPad,
                            placeholder: "0",
                            autocorrectionType: .no
                        ).setup { [weak self] view in
                            view.becomeFirstResponder()
                            view.text = viewModel.input.amount.toString()
                            view.textPublisher
                                .map { $0?.fiatFormat }
                                .sink { [weak self, weak view] text in
                                    view?.text = text
                                    self?.viewModel.setAmount(value: Double(text ?? "") ?? 0)
                                }
                                .store(in: &subscriptions)
                            NotificationCenter.default.publisher(
                                for: UITextField.textDidEndEditingNotification,
                                object: view
                            )
                                .sink { [weak view] _ in
                                    view?.text = view?.text?.withoutLastZeros
                                }
                                .store(in: &subscriptions)
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
                        CoinLogoImageView(size: 20, cornerRadius: 9)
                            .setup { view in
                                viewModel.solanaTokenPublisher
                                    .sink { [weak view] token in
                                        view?.setUp(token: token)
                                    }
                                    .store(in: &subscriptions)
                            }
                        UIView(width: 4)
                        UILabel(text: "0.00 \(viewModel.crypto)").setup { view in
                            viewModel.outputAnyPublisher
                                .map { [weak self] output in
                                    "\(output.amount) \(self?.viewModel.crypto.name ?? "?")"
                                }
                                .assign(to: \.text, on: view)
                                .store(in: &subscriptions)
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
