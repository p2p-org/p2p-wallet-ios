//
//  TransactionView.swift
//  p2p_wallet
//
//  Created by Ivan on 19.04.2022.
//

import BEPureLayout
import RxCocoa
import RxGesture
import RxSwift
import SolanaSwift
import UIKit

extension History {
    final class TransactionView: BECompositionView {
        private let descriptionSpacing: CGFloat = 12

        private let imageView = TransactionImageView(
            size: 64,
            backgroundColor: .grayPanel,
            cornerRadius: 16,
            basicIconSize: 32,
            miniIconsSize: 39
        )
        private let amountLabel = UILabel(
            textSize: 16,
            weight: .bold,
            textColor: .black,
            numberOfLines: 1
        )
        private let usdAmountLabel = UILabel(
            textSize: 20,
            weight: .medium,
            textColor: .gray,
            numberOfLines: 1
        )
        private let blockTimeLabel = UILabel(
            textSize: 14,
            weight: .regular,
            textColor: .gray,
            numberOfLines: 1
        )
        private lazy var fromAddressLabel = descriptionLabel()
        private lazy var fromAddressView = addressView(title: L10n.from, label: fromAddressLabel)
        private lazy var toAddressLabel = descriptionLabel()
        private lazy var toAddressView = addressView(title: L10n.to, label: toAddressLabel)

        private let modelRelay = PublishRelay<Model>()
        private var model: Driver<Model> { modelRelay.asDriver() }

        fileprivate var transactionIdClicked = PublishRelay<Void>()
        fileprivate var doneClicked = PublishRelay<Void>()
        fileprivate var transactionDetailClicked = PublishRelay<Void>()

        private let disposeBag = DisposeBag()

        override func build() -> UIView {
            BESafeArea {
                BEVStack(spacing: 28) {
                    BEVStack(spacing: 30) {
                        BEVStack(spacing: 30, alignment: .center) {
                            imageView.padding(.init(only: .top, inset: 24))
                            BEVStack(spacing: 12, alignment: .center) {
                                amountLabel
                                usdAmountLabel
                                blockTimeLabel
                            }
                        }
                        BEVStack(spacing: 23) {
                            transactionIdView
                            fromAddressView
                            toAddressView
                            feeView
                            statusView
                            blockNumberView
                        }
                    }
                    BEVStack(spacing: 8) {
                        UIButton(
                            height: 64,
                            backgroundColor: ._5887ff,
                            label: L10n.done,
                            labelFont: .systemFont(ofSize: 17, weight: .medium)
                        ).setup {
                            $0.layer.cornerRadius = 12
                            $0.rx.controlEvent(.touchUpInside)
                                .bind(to: doneClicked)
                                .disposed(by: disposeBag)
                        }
                        UIButton(
                            height: 64,
                            label: L10n.transactionDetail,
                            labelFont: .systemFont(ofSize: 17, weight: .medium),
                            textColor: ._5887ff
                        ).setup {
                            $0.rx.controlEvent(.touchUpInside)
                                .bind(to: transactionDetailClicked)
                                .disposed(by: disposeBag)
                        }
                        .padding(.init(only: .bottom, inset: 8))
                    }
                }
                .padding(.init(x: 16, y: 0))
            }
        }

        private var transactionIdView: UIView {
            BEHStack(spacing: descriptionSpacing, alignment: .top) {
                descriptionTitleLabel(text: L10n.transactionID)
                BEHStack(spacing: 6, alignment: .center) {
                    descriptionLabel().setup {
                        model.map(\.transactionId)
                            .drive($0.rx.text)
                            .disposed(by: disposeBag)
                    }
                    UIImageView(
                        width: 20,
                        height: 20,
                        image: .transactionsCopy,
                        tintColor: .textSecondary
                    )
                }
                .setup { view in
                    view.rx.tapGesture()
                        .when(.recognized)
                        .mapToVoid()
                        .bind(to: transactionIdClicked)
                        .disposed(by: disposeBag)
                }
            }
        }

        private func addressView(title: String, label: UILabel) -> UIView {
            BEHStack(spacing: descriptionSpacing, alignment: .top) {
                descriptionTitleLabel(text: title)
                    .withContentHuggingPriority(.required, for: .horizontal)
                label
            }
        }

        private var feeView: UIView {
            BEHStack(spacing: descriptionSpacing, alignment: .top) {
                descriptionTitleLabel(text: L10n.fee)
                    .withContentHuggingPriority(.required, for: .horizontal)
                descriptionLabel().setup {
                    model.map(\.fee)
                        .drive($0.rx.attributedText)
                        .disposed(by: disposeBag)
                }
            }
        }

        private var statusView: UIView {
            BEHStack(spacing: descriptionSpacing, alignment: .top) {
                descriptionTitleLabel(text: L10n.status)
                    .withContentHuggingPriority(.required, for: .horizontal)
                descriptionLabel().setup {
                    model.map(\.status.text)
                        .drive($0.rx.text)
                        .disposed(by: disposeBag)
                    model.map(\.status.color)
                        .drive($0.rx.textColor)
                        .disposed(by: disposeBag)
                }
            }
        }

        private var blockNumberView: UIView {
            BEHStack(spacing: descriptionSpacing, alignment: .top) {
                descriptionTitleLabel(text: L10n.blockNumber)
                    .withContentHuggingPriority(.required, for: .horizontal)
                descriptionLabel().setup {
                    model.map(\.blockNumber)
                        .drive($0.rx.text)
                        .disposed(by: disposeBag)
                }
            }
        }

        private func descriptionTitleLabel(text: String) -> UILabel {
            UILabel(
                text: text,
                textSize: 16,
                textColor: .black,
                numberOfLines: 1
            )
        }

        private func descriptionLabel() -> UILabel {
            UILabel(
                textSize: 16,
                textColor: .secondaryLabel,
                textAlignment: .right
            )
        }

        fileprivate func setModel(_ model: Model) {
            imageView.setUp(imageType: model.imageType)
            amountLabel.text = model.amount
            amountLabel.isHidden = model.amount == nil
            usdAmountLabel.text = model.usdAmount
            usdAmountLabel.isHidden = model.usdAmount == nil
            blockTimeLabel.text = model.blockTime
            toAddressView.isHidden = model.addresses.to == nil
            toAddressLabel.text = model.addresses.to
            fromAddressView.isHidden = model.addresses.from == nil
            fromAddressLabel.text = model.addresses.from

            modelRelay.accept(model)
        }
    }
}

extension History.TransactionView {
    struct Model {
        let imageType: TransactionImageView.ImageType
        let amount: String?
        let usdAmount: String?
        let blockTime: String
        let transactionId: String
        let addresses: (from: String?, to: String?)
        let fee: NSAttributedString?
        let status: Status
        let blockNumber: String
    }

    struct Status {
        let text: String
        let color: UIColor
    }
}

extension Reactive where Base == History.TransactionView {
    var model: Binder<Base.Model> {
        Binder(base) { $0.setModel($1) }
    }

    var transactionIdClicked: Observable<Void> { base.transactionIdClicked.asObservable() }
    var doneClicked: Observable<Void> { base.doneClicked.asObservable() }
    var transactionDetailClicked: Observable<Void> { base.transactionDetailClicked.asObservable() }
}
