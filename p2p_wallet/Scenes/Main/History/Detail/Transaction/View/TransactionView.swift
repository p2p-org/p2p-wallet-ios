//
//  TransactionView.swift
//  p2p_wallet
//
//  Created by Ivan on 19.04.2022.
//

import BEPureLayout
import KeyAppUI
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
            miniIconsSize: 39,
            statusIconSize: .init(width: 24, height: 24)
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
        private lazy var usernameLabel = descriptionLabel()
        private lazy var usernameView = usernameView(title: L10n.username, label: usernameLabel)
        private lazy var addressLabel = descriptionLabel()
        private lazy var addressView = addressView(title: L10n.address, label: addressLabel, keyPath: \.address)
        private lazy var addressFromLabel = descriptionLabel()
        private lazy var addressFromView = addressView(
            title: L10n.from,
            label: addressFromLabel,
            keyPath: \.addresses.from
        )
        private lazy var addressToLabel = descriptionLabel()
        private lazy var addressToView = addressView(title: L10n.to, label: addressToLabel, keyPath: \.addresses.to)

        private let modelRelay = PublishRelay<Model>()
        private var model: Driver<Model> { modelRelay.asDriver() }
        private let usernameRelay = PublishRelay<String?>()
        private var username: Driver<String?> { usernameRelay.asDriver() }

        fileprivate var transactionIdClicked = PublishRelay<Void>()
        fileprivate var usernameClicked = PublishRelay<Void>()
        fileprivate var addressClicked = PublishRelay<KeyPath<Model, String?>>()
        fileprivate var doneClicked = PublishRelay<Void>()
        fileprivate var transactionDetailClicked = PublishRelay<Void>()

        private let disposeBag = DisposeBag()

        override func build() -> UIView {
            BEZStack {
                BEZStackPosition(mode: .fill) {
                    BESafeArea {
                        BEVStack(spacing: 28) {
                            BEVStack(spacing: 30) {
                                BEVStack(spacing: 30, alignment: .center) {
                                    imageView.padding(.init(only: .top, inset: 24))
                                    BEVStack(spacing: 12, alignment: .center) {
                                        amountLabel
                                            .frame(height: 16)
                                        usdAmountLabel
                                            .frame(height: 16)
                                        blockTimeLabel
                                            .frame(height: 16)
                                    }
                                }
                                BEVStack(spacing: 23) {
                                    usernameView
                                    addressView
                                    addressFromView.setup { $0.isHidden = true }
                                    addressToView.setup { $0.isHidden = true }
                                    feeView
                                    statusView
                                    transactionIdView
                                    UIView().setup {
                                        $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                                        $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
                                    }
                                }
                            }
                            BEVStack(spacing: 8) {
                                TextButton(
                                    title: L10n.done,
                                    style: .primary,
                                    size: .large
                                ).setup {
                                    $0.layer.cornerRadius = 12
                                }.onPressed { [weak self] _ in
                                    self?.doneClicked.accept(())
                                }
                                TextButton(
                                    title: L10n.transactionDetail,
                                    style: .ghost,
                                    size: .large
                                )
                                .onPressed { [weak self] _ in
                                    self?.transactionDetailClicked.accept(())
                                }
                                .padding(.init(only: .bottom, inset: 8))
                            }
                        }
                        .padding(.init(x: 16, y: 0))
                    }
                }

                placeholder
                    .setup { $0.isUserInteractionEnabled = false }
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

        private func addressView(title: String, label: UILabel, keyPath: KeyPath<Model, String?>) -> UIView {
            BEHStack(spacing: descriptionSpacing, alignment: .top) {
                descriptionTitleLabel(text: title)
                BEHStack(spacing: 6, alignment: .center) {
                    label.setup {
                        model.map { $0[keyPath: keyPath] }
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
                        .map { _ in keyPath }
                        .bind(to: addressClicked)
                        .disposed(by: disposeBag)
                }
            }
        }

        private func usernameView(title _: String, label: UILabel) -> UIView {
            BEHStack(spacing: descriptionSpacing, alignment: .top) {
                descriptionTitleLabel(text: L10n.username)
                BEHStack(spacing: 6, alignment: .center) {
                    label.setup {
                        username
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
                        .bind(to: usernameClicked)
                        .disposed(by: disposeBag)
                }
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
            imageView.setUp(imageType: model.imageType.imageType)
            imageView.setUp(statusImage: model.imageType.statusImage)
            amountLabel.text = model.amount
            amountLabel.isHidden = model.amount == nil
            usdAmountLabel.text = model.usdAmount
            usdAmountLabel.isHidden = model.usdAmount == nil
            blockTimeLabel.text = model.blockTime
            usernameView.isHidden = model.username == nil
            if usernameView.isHidden {
                usernameView.removeFromSuperview()
            }
            usernameLabel.text = model.username
            addressView.isHidden = model.address == nil
            addressLabel.text = model.address

            addressFromView.isHidden = model.addresses.from == nil
            addressFromLabel.text = model.addresses.from
            addressToView.isHidden = model.addresses.to == nil
            addressToLabel.text = model.addresses.to

            modelRelay.accept(model)
            hideSkeleton()
        }

        // MARK: - Skeleton

        func skeletonPlaceholder() -> UIView {
            BEZStackPosition(mode: .fill) {
                BESafeArea {
                    BEVStack(spacing: 28) {
                        BEVStack(spacing: 30, alignment: .center) {
                            TransactionImageView(
                                size: 64,
                                backgroundColor: .grayPanel,
                                cornerRadius: 16,
                                basicIconSize: 32,
                                miniIconsSize: 39,
                                statusIconSize: .init(width: 24, height: 24)
                            )
                            .setup { $0.layer.cornerRadius = 16 }
                            BEVStack(spacing: 12, alignment: .center) {
                                UILabel(text: "             ")
                                    .frame(height: 16)
                                UILabel(text: "             ")
                                UILabel(text: "                  ")
                            }
                        }
                        .padding(.init(only: .top, inset: 24))
                        .setup { stack in
                            stack.showLoader()
                        }
                        BEVStack(spacing: 23) {
                            usernameView(title: L10n.username, label: UILabel(
                                text: "              "
                            ))
                            .setup { $0.showLoader() }
                            usernameView(title: L10n.username, label: UILabel(
                                text: "              "
                            ))
                            .setup { $0.showLoader() }
                            usernameView(title: L10n.username, label: UILabel(
                                text: "              "
                            ))
                            .setup { $0.showLoader() }
                            usernameView(title: L10n.username, label: UILabel(
                                text: "              "
                            ))
                            .setup { $0.showLoader() }
                            usernameView(title: L10n.username, label: UILabel(
                                text: "              "
                            ))
                            .setup { $0.showLoader() }
                            UIView()
                        }
                    }
                }
                .padding(.init(x: 16, y: 0))
                .setup { $0.isUserInteractionEnabled = false }
            }
        }

        lazy var placeholder = skeletonPlaceholder()

        func hideSkeleton() {
            UIView.animate(withDuration: 0.5) {
                self.placeholder.isHidden = true
                self.placeholder.alpha = 0
            }
            placeholder.hideLoader()
        }
    }
}

extension History.TransactionView {
    struct Model {
        let imageType: (imageType: TransactionImageView.ImageType, statusImage: UIImage?)
        let amount: String?
        let usdAmount: String?
        let blockTime: String
        let transactionId: String
        let address: String?
        let addresses: (from: String?, to: String?)
        let username: String?
        let fee: NSAttributedString?
        let status: Status
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
    var usernameClicked: Observable<Void> { base.usernameClicked.asObservable() }
    var addressClicked: Observable<KeyPath<Base.Model, String?>> { base.addressClicked.asObservable() }
}
