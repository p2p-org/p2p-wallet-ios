//
// Created by Giang Long Tran on 04.03.2022.
//

import Foundation
import Resolver
import RxSwift
import SolanaSwift

extension BuyPreparing {
    final class InputCryptoView: BECompositionView {
        private let disposeBag = DisposeBag()
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
                                Single<[Token]>.async {
                                    Array(try await Resolver.resolve(SolanaTokensRepository.self).getTokensList())
                                }
                                .asDriver(onErrorJustReturn: [])
                                .drive(onNext: { [weak self, weak view] tokens in
                                    if let token = tokens.first(where: { token in
                                        self?.viewModel.crypto == .sol ? token.symbol == "SOL" : token
                                            .symbol.lowercased() == self?.viewModel.crypto.solanaCode
                                            .lowercased() && token.address == self?.viewModel.crypto.mintAddress
                                    }) {
                                        view?.setUp(token: token)
                                    }
                                })
                                .disposed(by: disposeBag)
                            }
                        UIView(width: 8)

                        TokenAmountTextField(
                            font: .systemFont(ofSize: 27, weight: .semibold),
                            textColor: .textBlack,
                            textAlignment: .right,
                            keyboardType: .decimalPad,
                            placeholder: "0",
                            autocorrectionType: .no
                        ).setup { [weak self] view in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                view.becomeFirstResponder()
                            }
                            view.delegate = self
                            view.text = viewModel.input.amount.toString()
                            view.rx.text
                                .subscribe(onNext: { [weak viewModel] text in
                                    viewModel?.setAmount(value: Double(text ?? "") ?? 0)
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
