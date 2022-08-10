//
// Created by Giang Long Tran on 04.03.2022.
//

import Combine
import CombineCocoa
import Foundation
import Resolver
import SolanaSwift

extension BuyPreparing {
    final class InputCryptoView: BECompositionView {
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
                        UILabel(text: L10n.youGet, textSize: 17)
                        UIView.spacer
                        // Amount
                        CoinLogoImageView(size: 24, cornerRadius: 8)
                            .setup { view in
                                viewModel.solanaTokenPublisher
                                    .sink { [weak view] token in
                                        view?.setUp(token: token)
                                    }
                                    .store(in: &subscriptions)
                            }
                        UIView(width: 8)

                        TokenAmountTextField(
                            font: .systemFont(ofSize: 27, weight: .semibold),
                            textColor: .textBlack,
                            textAlignment: .right,
                            keyboardType: .decimalPad,
                            placeholder: "0",
                            autocorrectionType: .no
                        ).setup { view in
                            view.becomeFirstResponder()
                            view.text = viewModel.input.amount.toString()
                            view.textPublisher
                                .sink { [weak viewModel] text in
                                    viewModel?.setAmount(value: Double(text ?? "") ?? 0)
                                }
                                .store(in: &subscriptions)
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
                            viewModel.outputAnyPublisher
                                .map { output in "$ \(output.amount)" }
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
