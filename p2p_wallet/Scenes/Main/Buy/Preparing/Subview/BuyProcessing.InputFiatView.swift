//
// Created by Giang Long Tran on 04.03.2022.
//

import Foundation
import RxSwift

extension BuyPreparing {
    class InputFiatView: BECompositionView {
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
                            view.rx.text
                                .map { $0?.fiatFormat }
                                .subscribe(onNext: { [weak self, weak view] text in
                                    view?.text = text
                                    self?.viewModel.setAmount(value: Double(text ?? "") ?? 0)
                                })
                                .disposed(by: disposeBag)
                            view.rx.controlEvent(.editingDidEnd)
                                .asObservable()
                                .subscribe(onNext: { [weak view] in
                                    view?.text = view?.text?.withoutLastZeros
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
                        CoinLogoImageView(size: 20, cornerRadius: 9)
                            .setup { view in
                                Resolver
                                    .resolve(TokensRepository.self)
                                    .getTokensList()
                                    .asDriver(onErrorJustReturn: [])
                                    .drive(onNext: { [weak self, weak view] tokens in
                                        if let token = tokens.first(where: { token in
                                            self?.viewModel.crypto == .sol ? token.symbol == "SOL" : token
                                                .symbol == self?.viewModel.crypto.solanaCode
                                        }) {
                                            view?.setUp(token: token)
                                        }
                                    })
                                    .disposed(by: disposeBag)
                            }
                        UIView(width: 4)
                        UILabel(text: "0.00 \(viewModel.crypto)").setup { view in
                            viewModel.outputDriver
                                .map { [weak self] output in
                                    "\(output.amount) \(self?.viewModel.crypto.name ?? "?")"
                                }
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
