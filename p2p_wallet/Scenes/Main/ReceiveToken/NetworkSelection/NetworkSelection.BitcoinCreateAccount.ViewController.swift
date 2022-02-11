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
        }

        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }

        override var padding: UIEdgeInsets { .zero }

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

                    BEBuilder(driver: viewModel.payingWallet) { [weak self] selectedWallet in
                        guard let self = self else { return UIView() }
                        return WLCard {
                            BEHStack(alignment: .center) {
                                UIImageView(width: 44, height: 44, image: .squircleSolanaIcon)
                                BEVStack {
                                    BEHStack {
                                        if selectedWallet == nil {
                                            UILabel(text: L10n.tapToSelect)
                                        } else {
                                            UILabel(text: L10n.accountCreationFee, textSize: 13, textColor: .secondaryLabel)
                                            UILabel(text: "~0.5$", textSize: 13)
                                        }
                                    }
                                    UILabel(text: "0.509 USDC", textSize: 17, weight: .semibold)
                                }.padding(.init(only: .left, inset: 12))
                                UIView.defaultNextArrow()
                            }.padding(.init(x: 18, y: 14))
                        }.onTap {
                            let vm = ChooseWallet.ViewModel(selectedWallet: selectedWallet, handler: self, showOtherWallets: true)
                            let vc = ChooseWallet.ViewController(title: L10n.chooseWallet, viewModel: vm)
                            self.present(vc, animated: true)
                        }
                    }

                    ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC").asMarkdown())
                    ReceiveToken.textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59").asMarkdown())
                }.padding(.init(x: 18, y: 0))

                // Accept button
                WLStepButton.main(text: L10n.topUpYourAccount)
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

    func create() -> Completable
    func selectWallet(wallet: Wallet)
}

extension ReceiveToken.BitcoinCreateAccountScene {
    class ViewModel: BitcoinCreateAccountViewModelType {
        @Injected var solanaSDK: SolanaSDK
        @Injected var walletRepository: WalletsRepository
        @Injected var rentBTCService: RentBTC.Service
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
            ).flatMap { [weak self] id -> Single<Any?> in
                guard let self = self else { return .error(NSError(domain: "ReceiveToken.BitcoinCreateAccountScene.ViewModel", code: 1)) }
                return self.solanaSDK.waitForConfirmation(signature: id).andThen(.just(nil))
            }.asCompletable()
        }
    
        func selectWallet(wallet: Wallet) {
            payingWalletRelay.accept(wallet)
        }
    }
}

extension ReceiveToken.BitcoinCreateAccountScene: WalletDidSelectHandler {
    func walletDidSelect(_ wallet: Wallet) {

    }
}
