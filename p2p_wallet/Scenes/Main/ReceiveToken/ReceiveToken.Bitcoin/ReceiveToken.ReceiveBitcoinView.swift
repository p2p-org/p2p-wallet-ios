//
//  ReceiveToken.ReceiveBitcoinView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import RxCocoa
import Action

extension ReceiveToken {
    class ReceiveBitcoinView: BEView, ConditionViewDelegate {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: ReceiveTokenBitcoinViewModelType
        private let receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        
        // MARK: - Subviews
        private lazy var receiveRenBTCSwitcher = UISwitch()
        private lazy var receiveNormalBTCView = ReceiveSolanaView(viewModel: receiveSolanaViewModel)
        private lazy var receiveRenBTCView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
            conditionView
            addressView
        }
        private lazy var conditionView = ConditionView()
        private lazy var addressView = AddressView(viewModel: viewModel)
        
        // MARK: - Initializers
        init(
            viewModel: ReceiveTokenBitcoinViewModelType,
            receiveSolanaViewModel: ReceiveTokenSolanaViewModelType
        ) {
            self.viewModel = viewModel
            self.receiveSolanaViewModel = receiveSolanaViewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        private func layout() {
            let stackView = UIStackView(
                axis: .vertical,
                spacing: 20,
                alignment: .fill,
                distribution: .fill
            ) {
                switchField(text: L10n.iWantToReceiveRenBTC, switch: receiveRenBTCSwitcher)
                    .padding(.init(x: 20, y: 0))
                receiveNormalBTCView
                receiveRenBTCView
            }
            
            // add stackView
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
            
            // set min height to 200
            autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)
            
            // conditionView
            conditionView.delegate = self
        }
        
        private func bind() {
            receiveRenBTCSwitcher
                .addTarget(self, action: #selector(receiveRenBTCSwitcherDidTouch(sender:)), for: .valueChanged)
            
            viewModel.isReceivingRenBTCDriver
                .drive(receiveRenBTCSwitcher.rx.isOn)
                .disposed(by: disposeBag)
            
            viewModel.isReceivingRenBTCDriver
                .drive(receiveNormalBTCView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.isReceivingRenBTCDriver
                .map {!$0}
                .drive(receiveRenBTCView.rx.isHidden)
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
            
            viewModel.conditionAcceptedDriver
                .drive(conditionView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.conditionAcceptedDriver
                .map {!$0}
                .drive(addressView.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        fileprivate func conditionViewButtonConfirmDidTouch(_ conditionView: ConditionView) {
            viewModel.acceptConditionAndLoadAddress()
        }
        
        @objc private func receiveRenBTCSwitcherDidTouch(sender: UISwitch) {
            viewModel.toggleIsReceivingRenBTC(isReceivingRenBTC: sender.isOn)
        }
    }
}

private protocol ConditionViewDelegate: AnyObject {
    func conditionViewButtonConfirmDidTouch(_ conditionView: ConditionView)
}

private class ConditionView: BEView {
    private let disposeBag = DisposeBag()
    fileprivate weak var delegate: ConditionViewDelegate?
    private lazy var completeTxWithinTimeSwitcher = UISwitch()
    private lazy var confirmButton = WLButton.stepButton(type: .blue, label: L10n.showAddress)
        .onTap(self, action: #selector(buttonConfirmDidTouch))
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
            
            UIStackView(axis: .horizontal, spacing: 8, alignment: .top, distribution: .fill) {
                UIImageView(width: 36, height: 36, image: .warning)
                
                UILabel(text: nil, numberOfLines: 0)
                    .withAttributedText(
                        NSMutableAttributedString()
                            .text(L10n.bitcoinDepositAddress, size: 15)
                            .text(" ", size: 15)
                            .text(L10n.isOnlyOpenFor36Hours, size: 15, weight: .semibold)
                            .text(", ", size: 15)
                            .text(L10n.butYouCanSendToItMultipleTimesWithinThisSession, size: 15)
                            .text(".", size: 15)
                    )
            }
                .padding(.init(x: 16, y: 12), backgroundColor: .a3a5ba.withAlphaComponent(0.05), cornerRadius: 12)
            
            textBuilder(text: L10n.EachTransactionToThisDepositAddressTakesAbout60MinutesToComplete.forSecurityReasonsYouWillNeedToWaitFor6BlockConfirmationsBeforeYouCanMintRenBTCOnSolana)
            
            textBuilder(text: L10n.ifYouCannotCompleteThisTransactionWithinTheRequiredTimePleaseReturnAtALaterDate)
            
            textBuilder(text: L10n.ifYouDoNotFinishYourTransactionWithinThisPeriodSessionTimeFrameYouRiskLosingTheDeposits)
            
            switchField(
                text: L10n.iCanCompleteThisTransactionWithinTime,
                switch: completeTxWithinTimeSwitcher
            )
            
            BEStackViewSpacing(20)
            
            confirmButton
        }
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))
        
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
        delegate?.conditionViewButtonConfirmDidTouch(self)
    }
}

private class AddressView: BEView {
    private let disposeBag = DisposeBag()
    private let viewModel: ReceiveTokenBitcoinViewModelType
    private var label3: UILabel!
    private var qrCodeView: ReceiveToken.QrCodeView!
    private var isCopying = false
    private var currentAddress: String?
    
    private lazy var loadingView = BESpinnerView(size: 30, endColor: .h5887ff)
    private lazy var addressLabel = UILabel(text: nil, textSize: 15, weight: .semibold, textAlignment: .center)
        .lineBreakMode(.byTruncatingMiddle)
    
    init(viewModel: ReceiveTokenBitcoinViewModelType) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        
        let text1 = L10n.ThisAddressAccepts.youMayLoseAssetsBySendingAnotherCoin(L10n.onlyBitcoin)
        let line1 = textBuilder(text: text1)
        semiboldText(L10n.onlyBitcoin, in: line1.arrangedSubviews.last as! UILabel)
        
        let text2 = L10n.minimumTransactionAmountOf("0.000112 BTC")
        let line2 = textBuilder(text: text2)
        semiboldText("0.000112 BTC", in: line2.arrangedSubviews.last as! UILabel)
        
        let line3 = textBuilder(text: L10n.isTheRemainingTimeToSafelySendTheAssets("35:59:59"))
        label3 = (line3.arrangedSubviews.last as! UILabel)
        
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
                .padding(.init(x: 20, y: 0))
            
            UILabel(text: L10n.viewInExplorer, textSize: 17, weight: .medium, textColor: .textSecondary, textAlignment: .center)
                .onTap(self, action: #selector(showBTCAddressInExplorer))
                .centeredHorizontallyView
                .padding(.init(x: 20, y: 9))
        }
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))
        
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
        
        viewModel.addressDriver
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.addressDriver
            .drive(onNext: {[weak self] address in
                self?.qrCodeView.setUp(string: address)
                self?.currentAddress = address
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
}

private func switchField(text: String, switch: UISwitch) -> UIView {
    UIStackView(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill) {
        UILabel(text: text, textSize: 15, weight: .semibold, numberOfLines: 0)
        `switch`
            .withContentHuggingPriority(.required, for: .horizontal)
    }
        .padding(.init(all: 20), cornerRadius: 12)
        .border(width: 1, color: .f6f6f8.onDarkMode(.white.withAlphaComponent(0.5)))
}

private func textBuilder(text: String) -> UIStackView {
    UIStackView(axis: .horizontal, spacing: 10, alignment: .top, distribution: .fill) {
        UIView(width: 3, height: 3, backgroundColor: .textBlack, cornerRadius: 1.5)
            .padding(.init(x: 0, y: 8))
        UILabel(text: nil, textSize: 15, numberOfLines: 0)
            .withAttributedText(
                NSMutableAttributedString()
                    .text(text, size: 15),
                lineSpacing: 8
            )
    }
}
