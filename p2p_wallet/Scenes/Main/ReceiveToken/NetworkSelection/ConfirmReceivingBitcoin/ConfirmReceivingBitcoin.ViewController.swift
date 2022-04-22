//
//  ConfirmReceivingBitcoin.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import BEPureLayout
import Foundation
import RxSwift
import UIKit

extension ConfirmReceivingBitcoin {
    class ViewController: WLModalViewController {
        // MARK: - Properties

        private let viewModel: ConfirmReceivingBitcoinViewModelType

        // MARK: - Initializer

        init(viewModel: ConfirmReceivingBitcoinViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - View builder

        override func build() -> UIView {
            BEVStack {
                // Receiving via bitcoin network
                UILabel(
                    text: L10n.receivingViaBitcoinNetwork,
                    textSize: 20,
                    weight: .semibold,
                    numberOfLines: 0,
                    textAlignment: .center
                )
                    .padding(.init(top: 18, left: 18, bottom: 4, right: 18))

                // Make sure you understand the aspect
                UILabel(
                    text: L10n.makeSureYouUnderstandTheseAspects,
                    textSize: 15,
                    textColor: .textSecondary,
                    numberOfLines: 0,
                    textAlignment: .center
                )
                    .padding(.init(top: 0, left: 18, bottom: 18, right: 18))
                    .setup { label in
                        viewModel.outputDriver.map { $0.accountStatus != .payingWalletAvailable }
                            .drive(label.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                // Alert and separator
                UIView()
                    .setup { view in
                        let separator = UIView.defaultSeparator()
                        view.addSubview(separator)
                        separator.autoAlignAxis(toSuperviewAxis: .horizontal)
                        separator.autoPinEdge(toSuperviewEdge: .leading)
                        separator.autoPinEdge(toSuperviewEdge: .trailing)

                        let imageView = UIImageView(width: 44, height: 44, image: .squircleAlert)
                        view.addSubview(imageView)
                        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
                        imageView.autoPinEdge(toSuperviewEdge: .top)
                        imageView.autoPinEdge(toSuperviewEdge: .bottom)
                    }
                    .padding(.init(only: .bottom, inset: 18))

                // Descripton label
                contentView()
                    .padding(.init(top: 0, left: 18, bottom: 36, right: 18))

                // Button stack view
                buttonsView()
                    .padding(.init(top: 0, left: 18, bottom: 0, right: 18))
            }
        }

        func contentView() -> UIView {
            BEVStack(spacing: 12) {
                topUpRequiredView()
                    .setup { view in
                        viewModel.outputDriver.map(\.accountStatus)
                            .map { $0 != .topUpRequired }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }

                createRenBTCView()
                    .setup { view in
                        viewModel.outputDriver.map(\.accountStatus)
                            .map { $0 != .payingWalletAvailable }
                            .drive(view.rx.isHidden)
                            .disposed(by: disposeBag)
                    }
            }
        }

        func topUpRequiredView() -> BEVStack {
            BEVStack(spacing: 12) {
                createExplanationView(
                    mainString: L10n.aToReceiveBitcoinsOverTheBitcoinNetwork(L10n.renBTCAccountIsRequired),
                    boldString: L10n.renBTCAccountIsRequired
                )

                createExplanationView(
                    mainString: L10n
                        .yourWalletListDoesNotContainARenBTCAccountAndToCreateOne(L10n
                            .youNeedToMakeATransaction),
                    boldString: L10n
                        .youNeedToMakeATransaction
                )

                createExplanationView(
                    mainString: L10n
                        .youToPayForAccountCreationButIfSomeoneSendsRenBTCToYourAddressItWillBeCreatedForYou(L10n
                            .donTHaveFunds),
                    boldString: L10n
                        .donTHaveFunds
                )
            }
        }

        func createRenBTCView() -> BEVStack {
            BEVStack(spacing: 12) {
                createExplanationView(
                    mainString: L10n
                        .yourWalletListDoesNotContainARenBTCAccountAndToCreateOne(L10n
                            .youNeedToMakeATransaction) + " " + L10n.youCanChooseWhichCurrencyToPayInBelow,
                    boldString: L10n
                        .youNeedToMakeATransaction
                )

                WLCard {
                    BEHStack(spacing: 12, alignment: .center) {
                        CoinLogoImageView(size: 44)

                        BEVStack(spacing: 4) {
                            UILabel(
                                text: "Account creation fee:",
                                textSize: 13,
                                textColor: .textSecondary,
                                numberOfLines: 0
                            )
                            UILabel(text: "0.509 USDC", textSize: 17, weight: .semibold)
                        }

                        UIView.defaultNextArrow()
                    }
                    .padding(.init(x: 18, y: 14))
                }
                .padding(.init(only: .bottom, inset: 12))

                createExplanationView(
                    mainString: L10n
                        .ThisAddressAccepts.youMayLoseAssetsBySendingAnotherCoin(L10n.onlyBitcoin),
                    boldString: L10n.onlyBitcoin
                )

                createExplanationView(
                    mainString: L10n
                        .minimumTransactionAmountOf("0.000112 BTC"),
                    boldString: "0.000112 BTC"
                )

                createExplanationView(
                    mainString: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59"),
                    boldString: "35:59:59"
                )
            }
        }

        func buttonsView() -> BEVStack {
            BEVStack(spacing: 10) {}
        }

        // MARK: - Binding

        override func bind() {
            super.bind()
            viewModel.outputDriver.map(\.isLoading)
                .drive(onNext: { [weak self] isLoading in
                    isLoading ? self?.showIndetermineHud() : self?.hideHud()
                })
                .disposed(by: disposeBag)

            viewModel.outputDriver
                .debounce(.milliseconds(100))
                .drive(onNext: { [weak self] _ in
                    self?.updatePresentationLayout(animated: true)
                })
                .disposed(by: disposeBag)
        }

        // MARK: - Text builder

        private func createExplanationView(mainString: String, boldString: String) -> UIView {
            BEHStack(spacing: 10, alignment: .top) {
                UILabel(text: "•")
                    .withContentHuggingPriority(.required, for: .horizontal)
                    .withContentCompressionResistancePriority(.required, for: .horizontal)
                UILabel(text: nil, numberOfLines: 0)
                    .withAttributedText(
                        createExplanationAttributedString(
                            mainString: mainString,
                            boldString: boldString
                        )
                    )
                    .withContentHuggingPriority(.required, for: .horizontal)
            }
        }

        private func createExplanationAttributedString(mainString: String, boldString _: String) -> NSAttributedString {
            NSMutableAttributedString()
                .text(mainString, size: 15, color: .textBlack)
        }
    }
}
