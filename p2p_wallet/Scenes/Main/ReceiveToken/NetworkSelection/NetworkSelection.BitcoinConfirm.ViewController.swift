//
//  NetworkSelection.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 14.12.21.
//
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

extension ReceiveToken {
    class BitcoinConfirmScene: WLBottomSheet {
        private let sceneType: SceneType

        fileprivate let action = PublishSubject<Action>()

        private let viewModel: BitcoinCreateAccountViewModelType

        init(
            sceneType: SceneType,
            viewModel: BitcoinCreateAccountViewModelType
        ) {
            self.sceneType = sceneType
            self.viewModel = viewModel
            super.init()
        }

        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }

        override var padding: UIEdgeInsets { .zero }

        override func build() -> UIView? {
            UIStackView(axis: .vertical, alignment: .fill) {
                // Title
                UIStackView(axis: .vertical, alignment: .center) {
                    UILabel(text: L10n.receivingViaBitcoinNetwork, textSize: 20, weight: .semibold)
                        .padding(.init(only: .bottom, inset: 4))
                    if sceneType != .noBtcAccountAndFundsForPay {
                        UILabel(text: L10n.makeSureYouUnderstandTheseAspects, textColor: .textSecondary)
                    }
                }.padding(.init(all: 18, excludingEdge: .bottom))

                // Icon
                BEZStack {
                    UIView.defaultSeparator().withTag(1)
                    UIImageView(width: 44, height: 44, image: .squircleAlert)
                        .centered(.horizontal)
                        .withTag(2)
                }.setup { view in
                    if let subview = view.viewWithTag(1) {
                        subview.autoPinEdge(toSuperviewEdge: .left)
                        subview.autoPinEdge(toSuperviewEdge: .right)
                        subview.autoCenterInSuperView(leftInset: 0, rightInset: 0)
                    }
                    if let subview = view.viewWithTag(2) {
                        subview.autoPinEdgesToSuperviewEdges()
                    }
                }.padding(.init(x: 0, y: 18))

                descriptionContent
                buttonsContent.padding(.init(x: 18, y: 36))
            }
        }

        override func bind() {
            super.bind()

            if sceneType == .noBtcAccount {
                viewModel.isLoadingDriver
                    .drive(onNext: { [weak self] loading in
                        if loading {
                            self?.showIndetermineHud()
                        } else {
                            self?.hideHud()
                        }
                    })
                    .disposed(by: disposeBag)
            }
        }

        private var descriptionContent: UIView {
            UIStackView(axis: .vertical, spacing: 12, alignment: .fill) {
                switch sceneType {
                case .btcAccountCreated:
                    ReceiveToken
                        .textBuilder(
                            text: L10n.ThisAddressAcceptsOnly
                                .youMayLoseAssetsBySendingAnotherCoin(L10n.bitcoin)
                                .asMarkdown()
                        )
                    ReceiveToken
                        .textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown())
                    ReceiveToken
                        .textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())
                case .noBtcAccount:
                    ReceiveToken
                        .textBuilder(
                            text: L10n.YourWalletListDoesNotContainARenBTCAccountAndToCreateOne
                                .youCanChooseWhichCurrencyToPayInBelow(L10n.youNeedToMakeATransaction)
                                .asMarkdown()
                        )
                    noBtcAccountCard
                    ReceiveToken
                        .textBuilder(text: L10n.ThisAddressAcceptsOnly
                            .youMayLoseAssetsBySendingAnotherCoin(L10n.bitcoin).asMarkdown())
                    ReceiveToken
                        .textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown())
                    ReceiveToken
                        .textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())
                case .noBtcAccountAndFundsForPay:
                    ReceiveToken
                        .textBuilder(
                            text: L10n
                                .aToReceiveBitcoinsOverTheBitcoinNetwork(L10n.renBTCAccountIsRequired)
                                .asMarkdown()
                        )
                    ReceiveToken.textBuilder(
                        text: L10n
                            .yourWalletListDoesNotContainARenBTCAccountAndToCreateOne(L10n.youNeedToMakeATransaction)
                            .asMarkdown()
                    )
                    ReceiveToken.textBuilder(
                        text: L10n
                            .youToPayForAccountCreationButIfSomeoneSendsRenBTCToYourAddressItWillBeCreatedForYou(
                                L10n.donTHaveFunds
                            )
                            .asMarkdown()
                    )
                }
            }.padding(.init(x: 18, y: 0))
        }

        private var noBtcAccountCard: UIView {
            BEBuilder(driver: viewModel.payingWallet) { [weak self] selectedWallet in
                guard let self = self else { return UIView() }

                return WLCard {
                    BEHStack(alignment: .center) {
                        UIImageView(width: 44, height: 44).setup { view in
                            self.viewModel.payingWallet
                                .compactMap { $0?.token.logoURI }
                                .drive { [weak view] url in
                                    view?.setImage(urlString: url)
                                }
                                .disposed(by: self.disposeBag)
                        }
                        .box(cornerRadius: 12)
                        BEVStack {
                            BEHStack {
                                UILabel(
                                    text: L10n.accountCreationFee + " ",
                                    textSize: 13,
                                    textColor: .secondaryLabel
                                )
                                UILabel(text: "~0.0$", textSize: 13)
                                    .setup { label in
                                        self.viewModel
                                            .feeAmountInFiat
                                            .drive(label.rx.text)
                                            .disposed(by: self.disposeBag)
                                    }
                                UIView.spacer
                            }
                            UILabel(textSize: 17, weight: .semibold).setup { view in
                                self.viewModel.feeAmount
                                    .map { str in "~\(str)" }
                                    .drive(view.rx.text)
                                    .disposed(by: self.disposeBag)
                            }
                        }.padding(.init(only: .left, inset: 12))
                        UIView.defaultNextArrow()
                    }.padding(.init(x: 18, y: 14))
                }.onTap { [unowned self] in
                    let vm = ChooseWallet.ViewModel(
                        selectedWallet: selectedWallet,
                        handler: self,
                        showOtherWallets: false
                    )
                    let vc = ChooseWallet.ViewController(title: L10n.chooseWallet, viewModel: vm)
                    self.present(vc, animated: true)
                }
            }
        }

        private var buttonsContent: UIView {
            switch sceneType {
            case .btcAccountCreated:
                return WLStepButton.main(image: .check.withTintColor(.white), text: L10n.iUnderstand)
                    .padding(.init(only: .top, inset: 36))
                    .onTap { [unowned self] in
                        back()
                        action.onNext(.iUnderstand)
                    }
            case .noBtcAccount:
                return WLStepButton.main(text: "").setup { view in
                    viewModel.payingWallet
                        .map { $0 != nil }
                        .drive(view.rx.isEnabled)
                        .disposed(by: disposeBag)
                    viewModel.feeAmount
                        .map { str in L10n.payContinue(str) }
                        .drive(view.rx.text)
                        .disposed(by: disposeBag)
                }
                .onTap { [unowned self] in
                    viewModel.create()
                        .subscribe(onCompleted: { [unowned self] in
                            back()
                            action.onNext(.payAndContinue)
                        })
                        .disposed(by: disposeBag)
                }
            case .noBtcAccountAndFundsForPay:
                return UIStackView(axis: .vertical, spacing: 20, alignment: .fill) {
                    WLStepButton.main(image: .walletAdd.withTintColor(.white), text: L10n.topUpYourAccount)
                        .padding(.init(only: .top, inset: 36))
                        .onTap { [unowned self] in
                            back()
                            action.onNext(.topUpAccount)
                        }
                    UIButton(
                        height: 56,
                        label: L10n.shareYourSolanaNetworkAddress,
                        labelFont: .systemFont(ofSize: 17, weight: .medium),
                        textColor: .h5887ff
                    )
                        .onTap { [unowned self] in
                            back()
                            action.onNext(.shareSolanaAddress)
                        }
                }
            }
        }
    }
}

// MARK: - Model

extension ReceiveToken.BitcoinConfirmScene {
    enum SceneType {
        case btcAccountCreated
        case noBtcAccount
        case noBtcAccountAndFundsForPay
    }

    enum Action {
        case iUnderstand
        case topUpAccount
        case shareSolanaAddress
        case payAndContinue
    }
}

// MARK: - Reactive

extension Reactive where Base == ReceiveToken.BitcoinConfirmScene {
    var navigationAction: Observable<Base.Action> {
        base.action.asObservable()
    }
}

extension ReceiveToken.BitcoinConfirmScene: WalletDidSelectHandler {
    func walletDidSelect(_ wallet: Wallet) {
        viewModel.selectWallet(wallet: wallet)
    }
}
