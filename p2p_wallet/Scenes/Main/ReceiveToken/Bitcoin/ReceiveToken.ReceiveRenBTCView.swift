//
//  ReceiveToken.ReceiveRenBTCView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/09/2021.
//

import Foundation
import RxSwift
import RxCocoa
import Action

extension ReceiveToken {
    class ReceiveRenBTCView: BEView {
        // MARK: - Properties
        private let viewModel: ReceiveTokenBitcoinViewModelType
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private lazy var createWalletView = CreateWalletView(viewModel: viewModel)
        private lazy var conditionView = ConditionView(viewModel: viewModel)
        private lazy var addressView = AddressView(viewModel: viewModel)
        
        // MARK: - Initializer
        init(viewModel: ReceiveTokenBitcoinViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        private func layout() {
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                createWalletView
                conditionView
                addressView
            }
            
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))
        }
        
        private func bind() {
            let isRenBTCWalletCreatedDriver = viewModel.renBTCWalletCreatingDriver
                .map {$0.state == .loaded}
            
            isRenBTCWalletCreatedDriver
                .drive(createWalletView.rx.isHidden)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                isRenBTCWalletCreatedDriver,
                viewModel.conditionAcceptedDriver
            )
                .map { isRenBTCCreated, conditionalAccepted -> Bool in
                    if !isRenBTCCreated {return true}
                    return conditionalAccepted
                }
                .drive(conditionView.rx.isHidden)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                isRenBTCWalletCreatedDriver,
                viewModel.conditionAcceptedDriver
            )
                .map { isRenBTCCreated, conditionalAccepted -> Bool in
                    if !isRenBTCCreated {return true}
                    return !conditionalAccepted
                }
                .drive(addressView.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        fileprivate func conditionViewButtonConfirmDidTouch(_ conditionView: ConditionView) {
            viewModel.acceptConditionAndLoadAddress()
        }
    }
}

private class CreateWalletView: BEView {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewModel: ReceiveTokenBitcoinViewModelType
    
    // MARK: - Subviews
    private lazy var createATokenButton = WLButton.stepButton(
        type: .blue,
        label: L10n.createTokenAccount
    )
        .onTap(self, action: #selector(buttonCreateTokenAccountDidTouch))
    
    // MARK: - Initializers
    init(viewModel: ReceiveTokenBitcoinViewModelType) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        layout()
        bind()
    }
    
    func layout() {
        let stackView = UIStackView(axis: .vertical, spacing: 30, alignment: .fill, distribution: .fill) {
            warningView(
                attributedText: NSMutableAttributedString()
                    .text(L10n.SolanaAssociatedTokenAccountRequired
                            .thisWillRequireYouToSignATransactionAndSpendSomeSOL,
                          size: 15
                    )
            )
            
            createATokenButton
        }
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    func bind() {
        viewModel.renBTCWalletCreatingDriver
            .drive(onNext: {[weak self] params in
                let state = params.state
                switch state {
                case .notRequested:
                    self?.createATokenButton.setTitle(L10n.createTokenAccount, for: .normal)
                    self?.createATokenButton.isEnabled = true
                case .loading:
                    self?.createATokenButton.setTitle(L10n.creatingTokenAccount, for: .normal)
                    self?.createATokenButton.isEnabled = false
                case .loaded:
                    self?.createATokenButton.setTitle(L10n.createTokenAccount, for: .normal)
                    self?.createATokenButton.isEnabled = false
                case .error:
                    self?.createATokenButton.setTitle(L10n.error.uppercaseFirst + ". " + L10n.retry.uppercaseFirst + "?", for: .normal)
                    self?.createATokenButton.isEnabled = true
                }
            })
            .disposed(by: disposeBag)
    }
    
    @objc func buttonCreateTokenAccountDidTouch() {
        viewModel.createRenBTCWallet()
    }
}

private class ConditionView: BEView {
    private let viewModel: ReceiveTokenBitcoinViewModelType
    private let disposeBag = DisposeBag()
    private lazy var completeTxWithinTimeSwitcher = UISwitch()
    private lazy var confirmButton = WLButton.stepButton(type: .blue, label: L10n.showAddress)
        .onTap(self, action: #selector(buttonConfirmDidTouch))
    
    init(viewModel: ReceiveTokenBitcoinViewModelType) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
            
            warningView(
                attributedText:
                    NSMutableAttributedString()
                        .text(L10n.bitcoinDepositAddress, size: 15)
                        .text(" ", size: 15)
                        .text(L10n.isOnlyOpenFor36Hours, size: 15, weight: .semibold)
                        .text(", ", size: 15)
                        .text(L10n.butYouCanSendToItMultipleTimesWithinThisSession, size: 15)
                        .text(".", size: 15)
            )
            
            ReceiveToken.textBuilder(text: L10n.EachTransactionToThisDepositAddressTakesAbout60MinutesToComplete.forSecurityReasonsYouWillNeedToWaitFor6BlockConfirmationsBeforeYouCanMintRenBTCOnSolana)
            
            ReceiveToken.textBuilder(text: L10n.ifYouCannotCompleteThisTransactionWithinTheRequiredTimePleaseReturnAtALaterDate)
            
            ReceiveToken.textBuilder(text: L10n.ifYouDoNotFinishYourTransactionWithinThisPeriodSessionTimeFrameYouRiskLosingTheDeposits)
            
            UIView.switchField(
                text: L10n.iCanCompleteThisTransactionWithinTime,
                switch: completeTxWithinTimeSwitcher
            )
            
            BEStackViewSpacing(20)
            
            confirmButton
        }
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        bind()
    }
    
    private func bind() {
        completeTxWithinTimeSwitcher.rx.isOn
            .asDriver()
            .drive(confirmButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        completeTxWithinTimeSwitcher.rx.isOn
            .asDriver()
            .map {$0 ? L10n.showAddress: L10n.beSureYouCanCompleteThisTransaction}
            .drive(confirmButton.rx.title())
            .disposed(by: disposeBag)
    }
    
    @objc private func buttonConfirmDidTouch() {
        viewModel.acceptConditionAndLoadAddress()
    }
}

private class AddressView: BEView {
    private let disposeBag = DisposeBag()
    private let viewModel: ReceiveTokenBitcoinViewModelType
    private var label2: UILabel!
    private var label3: UILabel!
    private var qrCodeView: ReceiveToken.QrCodeView!
    private var isCopying = false
    private var currentAddress: String?
    
    private lazy var loadingView = BESpinnerView(size: 30, endColor: .h5887ff)
    private lazy var addressLabel = UILabel(text: nil, textSize: 15, weight: .semibold, textAlignment: .center)
        .lineBreakMode(.byTruncatingMiddle)
    private lazy var receivingStatusSection = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
        UILabel(text: L10n.receivingStatuses, textSize: 15, weight: .medium)
        UIView.defaultNextArrow()
    }
        .padding(.init(x: 20, y: 15))
        .onTap(self, action: #selector(buttonReceivingStatusDidTouch))
    
    init(viewModel: ReceiveTokenBitcoinViewModelType) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        
        let text1 = L10n.ThisAddressAccepts.youMayLoseAssetsBySendingAnotherCoin(L10n.onlyBitcoin)
        let line1 = ReceiveToken.textBuilder(text: text1)
        (line1.arrangedSubviews.last as! UILabel).text = text1
        semiboldText(L10n.onlyBitcoin, in: line1.arrangedSubviews.last as! UILabel)
        
        let line2 = ReceiveToken.textBuilder(text: L10n.minimumTransactionAmountOf("0.000112 BTC"))
        label2 = (line2.arrangedSubviews.last as! UILabel)
            .onTap(self, action: #selector(reloadMinimumTransactionAmount))
        
        let line3 = ReceiveToken.textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59"))
        label3 = line3.arrangedSubviews.last as? UILabel
        
        let qrCodeViewAndFrame = ReceiveToken.QrCodeView.withFrame()
            
        let frame = qrCodeViewAndFrame.0
        qrCodeView = qrCodeViewAndFrame.1
        
        let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
            line1
            line2
            line3
            
            BEStackViewSpacing(30)
            
            frame.centeredHorizontallyView
            
            BEStackViewSpacing(24)
            
            UIStackView(axis: .horizontal, spacing: 4, alignment: .fill, distribution: .fill) {
                addressLabel
                    .padding(.init(all: 20), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 4)
                    .onTap(self, action: #selector(copyBTCAddressToClipboard))
                
                UIImageView(width: 32, height: 32, image: .share, tintColor: .a3a5ba)
                    .onTap(self, action: #selector(share))
                    .padding(.init(all: 12), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 4)
            }
                .padding(.zero, cornerRadius: 12)
            
            BEStackViewSpacing(16)
            receivingStatusSection
            
            BEStackViewSpacing(50)
            ReceiveToken.viewInExplorerButton(
                title: L10n.viewInExplorer(L10n.bitcoin),
                target: self,
                selector: #selector(showBTCAddressInExplorer)
            )
        }
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        frame.addSubview(loadingView)
        loadingView.autoCenterInSuperview()
        loadingView.animate()
        
        bind()
    }
    
    private func bind() {
        viewModel.isLoadingDriver
            .map {!$0}
            .drive(loadingView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.errorDriver
            .drive(onNext: {[weak self] error in
                guard let self = self else {return}
                if let error = error {
                    self.showErrorView(
                        title: L10n.error,
                        description: error,
                        retryAction: CocoaAction { [weak self] in
                            self?.viewModel.reload()
                            return .just(())
                        }
                    )
                } else {
                    self.removeErrorView()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.addressDriver
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.addressDriver
            .drive(onNext: {[weak self] address in
                self?.qrCodeView.setUp(string: address, token: .renBTC)
                self?.currentAddress = address
            })
            .disposed(by: disposeBag)
        
        viewModel.minimumTransactionAmountDriver
            .drive(onNext: {[weak self] loadable in
                guard let self = self else {return}
                self.label2.isUserInteractionEnabled = false
                
                switch loadable.state {
                case .notRequested, .loading:
                    self.label2.text = L10n.calculatingMinimumTransactionAmount
                case .loaded:
                    let amount = (loadable.value ?? 0) * 2
                    let amountString = amount.toString(maximumFractionDigits: 9) + " BTC"
                    self.label2.text = L10n.minimumTransactionAmountOf(amountString)
                    self.semiboldText(amountString, in: self.label2)
                case .error:
                    self.label2.isUserInteractionEnabled = true
                    self.label2.text = L10n.error.uppercaseFirst + ". " + L10n.tapToTryAgain
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.timerSignal
            .emit(onNext: { [weak self] in
                guard let self = self else {return}
                guard let endAt = self.viewModel.getSessionEndDate()
                else {return}
                let currentDate = Date()
                let calendar = Calendar.current

                let d = calendar.dateComponents([.hour, .minute, .second], from: currentDate, to: endAt)
                let countdown = String(format: "%02d:%02d:%02d", d.hour ?? 0, d.minute ?? 0, d.second ?? 0)
                
                let text = L10n.isTheRemainingTimeToSafelySendTheAssets(countdown)
                
                self.label3.text = text
                self.semiboldText(countdown, in: self.label3)
            })
            .disposed(by: disposeBag)
        
        viewModel.processingTxsDriver
            .map {$0.isEmpty}
            .drive(receivingStatusSection.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func semiboldText(_ text: String, in label: UILabel) {
        let aStr = NSMutableAttributedString(string: label.text!)
        aStr.addAttribute(.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: NSString(string: label.text!).range(of: text))
        label.attributedText = aStr
    }
    
    @objc private func copyBTCAddressToClipboard() {
        guard !isCopying, let pubkey = currentAddress else {return}
        isCopying = true
        
        viewModel.copyToClipboard(address: pubkey, logEvent: .receiveAddressCopy)
        
        let addressLabelOriginalColor = addressLabel.textColor
        addressLabel.textColor = .h5887ff
        
        UIApplication.shared.showToast(
            message: "✅ " + L10n.addressCopiedToClipboard
        ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.addressLabel.textColor = addressLabelOriginalColor
                self?.isCopying = false
            }
        }
    }
    
    @objc private func share() {
        viewModel.share()
    }
    
    @objc private func showBTCAddressInExplorer() {
        viewModel.showBTCAddressInExplorer()
    }
    
    @objc private func reloadMinimumTransactionAmount() {
        viewModel.reloadMinimumTransactionAmount()
    }
    
    @objc private func buttonReceivingStatusDidTouch() {
        viewModel.showReceivingStatuses()
    }
}

private func warningView(attributedText: NSAttributedString) -> UIView {
    .greyBannerView(axis: .horizontal, alignment: .top) {
        UIImageView(width: 36, height: 36, image: .warning)
        
        UILabel(text: nil, numberOfLines: 0)
            .withAttributedText(attributedText)
    }
}
