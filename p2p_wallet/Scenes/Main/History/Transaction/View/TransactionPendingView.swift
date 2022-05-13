//
//  TransactionPendingView.swift
//  p2p_wallet
//
//  Created by Ivan on 13.05.2022.
//

import BEPureLayout
import RxCocoa
import RxGesture
import RxSwift
import UIKit

extension History {
    final class TransactionPendingView: BECompositionView {
        private let modelRelay = PublishRelay<Model>()
        private var model: Driver<Model> { modelRelay.asDriver() }

        fileprivate let doneClicked = PublishRelay<Void>()
        fileprivate let transactionDetailClicked = PublishRelay<Void>()

        private let disposeBag = DisposeBag()

        override func build() -> UIView {
            BESafeArea {
                BEVStack(spacing: 1) {
                    UIView(height: 139)
                    BEVStack(spacing: 186) {
                        BEVStack(spacing: 24) {
                            BEZStack {
                                BEZStackPosition(mode: .center) {
                                    AnimatedCircleCompletionView(width: 80, height: 80).setup { view in
                                        model
                                            .map { $0.state == .pending ? UIColor.f7931A : UIColor._1D864A }
                                            .drive(view.rx.color)
                                            .disposed(by: disposeBag)
                                        model
                                            .drive(onNext: { model in
                                                if model.state == .pending {
                                                    view.progressForever(interval: 2.0)
                                                    view.rotateForever()
                                                } else {
                                                    view.progress = 0.5
                                                }
                                            })
                                            .disposed(by: disposeBag)
                                    }
                                }
                                BEZStackPosition(mode: .center) {
                                    UIImageView().setup { imageView in
                                        imageView.image = .transactionTryAgain
                                        model
                                            .map { $0.state == .pending ? UIColor.f7931A : UIColor._1D864A }
                                            .drive(imageView.rx.tintColor)
                                            .disposed(by: disposeBag)
                                    }
                                }
                            }
                            BEVStack(spacing: 12, alignment: .center) {
                                UILabel(
                                    text: "112,35 USD",
                                    textSize: 22,
                                    weight: .bold,
                                    textColor: .black
                                ).setup {
                                    model
                                        .map(\.amount)
                                        .drive($0.rx.text)
                                        .disposed(by: disposeBag)
                                }
                                BEHStack(spacing: 13, alignment: .center) {
                                    UILabel(text: "4gj7UK2mG...NjweNS39N", textSize: 14).setup {
                                        model
                                            .map(\.transactionId)
                                            .drive($0.rx.text)
                                            .disposed(by: disposeBag)
                                    }
                                    UIImageView(
                                        width: 16,
                                        height: 16,
                                        image: .transactionShowInExplorer,
                                        tintColor: .textSecondary
                                    )
                                }.setup {
                                    $0.rx.tapGesture()
                                        .when(.recognized)
                                        .mapToVoid()
                                        .bind(to: transactionDetailClicked)
                                        .disposed(by: disposeBag)
                                }.setup {
                                    model
                                        .map(\.transactionId.isEmpty)
                                        .drive($0.rx.isHidden)
                                        .disposed(by: disposeBag)
                                }
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
                }
                .padding(.init(x: 16, y: 0))
            }
        }

        fileprivate func setModel(_ model: Model) {
            modelRelay.accept(model)
        }
    }
}

// MARK: - Model

extension History.TransactionPendingView {
    enum State {
        case pending
        case success
    }

    struct Model {
        let state: State
        let amount: String
        let transactionId: String
    }
}

// MARK: - Reactive

extension Reactive where Base == History.TransactionPendingView {
    var model: Binder<Base.Model> {
        Binder(base) { $0.setModel($1) }
    }

    var doneClicked: Observable<Void> { base.doneClicked.asObservable() }
    var transactionDetailClicked: Observable<Void> { base.transactionDetailClicked.asObservable() }
}
