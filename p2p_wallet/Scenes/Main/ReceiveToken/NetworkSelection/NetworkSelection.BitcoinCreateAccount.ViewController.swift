//
// Created by Giang Long Tran on 08.02.2022.
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

extension ReceiveToken {
    class BitcoinCreateAccountScene: WLBottomSheet {
        typealias ViewModelType = BitcoinCreateAccountViewModelType

        private let viewModel: ViewModelType
        private let onCompletion: BEVoidCallback?

        init(viewModel: ViewModelType, onCompletion: BEVoidCallback?) {
            self.viewModel = viewModel
            self.onCompletion = onCompletion
            super.init()

            self.viewModel
                .isLoadingDriver
                .drive(onNext: { [weak self] value in
                    if value {
                        self?.showIndetermineHud()
                    } else {
                        self?.hideHud()
                    }
                })
                .disposed(by: disposeBag)
        }

        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }

        override var padding: UIEdgeInsets { .zero }
    
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool { false }

        override func build() -> UIView? {
            UIStackView(axis: .vertical, alignment: .fill) {

                // Title
                UIStackView(axis: .vertical, alignment: .center) {
                    UILabel(text: L10n.receivingViaBitcoinNetwork, textSize: 20, weight: .semibold)
                        .padding(.init(only: .bottom, inset: 4))
                    UILabel(text: L10n.makeSureYouUnderstandTheAspects, textColor: .textSecondary)
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

                UIStackView(axis: .vertical, spacing: 12, alignment: .fill) {
                    ReceiveToken.textBuilder(text: L10n.yourWalletListDoesNotContainARenBTCAccountAndToCreateOneYouNeedToMakeATransaction.asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())

                    BEBuilder(driver: viewModel.payingWallet) { [weak self] selectedWallet in
                        guard let self = self else { return UIView() }

                        return WLCard {
                            BEHStack(alignment: .center) {
                                if selectedWallet == nil {
                                    UILabel(text: L10n.tapToSelect)
                                } else {
                                    UIImageView(width: 44, height: 44)
                                        .setupWithType(UIImageView.self) { view in
                                            self.viewModel
                                                .payingWallet
                                                .compactMap { $0?.token.logoURI }
                                                .drive { [weak view] url in view?.setImage(urlString: url) }
                                                .disposed(by: self.disposeBag)
                                        }
                                        .box(cornerRadius: 12)
                                    BEVStack {
                                        BEHStack {
                                            UILabel(text: L10n.accountCreationFee, textSize: 13, textColor: .secondaryLabel)
                                            UILabel(text: "~0.5$", textSize: 13)
                                        }
                                        UILabel(text: "", textSize: 17, weight: .semibold)
                                            .setupWithType(UILabel.self) { view in
                                                self.viewModel
                                                    .feeAmount
                                                    .map { str in "~\(str)" }
                                                    .drive(view.rx.text)
                                                    .disposed(by: self.disposeBag)
                                            }
                                    }.padding(.init(only: .left, inset: 12))
                                }
                                UIView.defaultNextArrow()
                            }.padding(.init(x: 18, y: 14))
                        }.onTap {
                            let vm = ChooseWallet.ViewModel(selectedWallet: selectedWallet, handler: self, showOtherWallets: false)
                            let vc = ChooseWallet.ViewController(title: L10n.chooseWallet, viewModel: vm)
                            self.present(vc, animated: true)
                        }
                    }
                }.padding(.init(x: 18, y: 0))

                // Accept button
                WLStepButton.main(text: "")
                    .setupWithType(WLStepButton.self) { view in
                        viewModel
                            .payingWallet
                            .map { $0 != nil }
                            .drive(view.rx.isEnabled)
                            .disposed(by: disposeBag)

                        viewModel
                            .feeAmount
                            .map { str in L10n.payContinue(str) }
                            .drive(view.rx.text)
                            .disposed(by: disposeBag)
                    }
                    .onTap { [unowned self] in
                        viewModel
                            .create()
                            .subscribe(onCompleted: {
                                self.back()
                                self.onCompletion?()
                            })
                            .disposed(by: disposeBag)
                    }
                    .padding(.init(x: 18, y: 36))
            }
        }
    }
}

protocol BitcoinCreateAccountViewModelType {
    var isLoadingDriver: Driver<Bool> { get }
    var payingWallet: Driver<Wallet?> { get }
    var feeAmount: Driver<String> { get }

    func create() -> Completable
    func selectWallet(wallet: Wallet)
}

extension ReceiveToken.BitcoinCreateAccountScene {
    class ViewModel: BitcoinCreateAccountViewModelType {
        @Injected var solanaSDK: SolanaSDK
        @Injected var walletRepository: WalletsRepository
        @Injected var rentBTCService: RentBTC.Service
        @Injected var notification: NotificationsServiceType
        private let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType

        private let payingWalletRelay: BehaviorRelay<Wallet?> = BehaviorRelay(value: nil)
        private let isLoadingRelay: BehaviorRelay<Bool> = BehaviorRelay(value: false)

        init(receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType) {
            self.receiveBitcoinViewModel = receiveBitcoinViewModel
            if let wallet = walletRepository.getWallets().first { $0.amount > 0 } {
                payingWalletRelay.accept(wallet)
            }
        }

        // MARK - Implementation BitcoinCreateAccountViewModelType
        var isLoadingDriver: Driver<Bool> { isLoadingRelay.asDriver() }
        var payingWallet: Driver<Wallet?> { payingWalletRelay.asDriver() }

        func create() -> Completable {
            isLoadingRelay.accept(true)
            guard
                let payingWallet = payingWalletRelay.value,
                let payingAddress = payingWallet.pubkey
            else {
                isLoadingRelay.accept(false)
                return .error(NSError(domain: "ReceiveToken.BitcoinCreateAccountScene.ViewModel.NotSelected", code: 1))
            }

            return rentBTCService.createAssociatedTokenAccount(
                payingFeeAddress: payingAddress,
                payingFeeMintAddress: payingWallet.mintAddress
            )
            .flatMap { [weak self] id -> Single<Any?> in
                print("HERE: \(id)")
                guard let self = self else { return .error(NSError(domain: "ReceiveToken.BitcoinCreateAccountScene.ViewModel", code: 1)) }
                return self.solanaSDK.waitForConfirmation(signature: id).andThen(.just(nil))
            }
            .do(onError: { [weak self] error in
                self?.notification.showInAppNotification(.error(error))
                self?.isLoadingRelay.accept(false)
            })
            .asCompletable()

        }

        func selectWallet(wallet: Wallet) {
            payingWalletRelay.accept(wallet)
        }

        var feeAmount: Driver<String> {
            payingWalletRelay
                .flatMap { [weak self] wallet -> Single<String> in
                    guard
                        let self = self,
                        let wallet = wallet,
                        let address = wallet.pubkey
                    else {
                        return .just("")
                    }

                    return self
                        .rentBTCService
                        .getCreationFee(payingFeeAddress: address, payingFeeMintAddress: wallet.mintAddress)
                        .map { lamports in "\(lamports.convertToBalance(decimals: wallet.token.decimals)) \(wallet.token.symbol)" }
                }
                .asDriver { error in
                    print(error)
                    return .just("")
                }
        }
    }
}

extension ReceiveToken.BitcoinCreateAccountScene: WalletDidSelectHandler {
    func walletDidSelect(_ wallet: Wallet) {
        viewModel.selectWallet(wallet: wallet)
    }
}
