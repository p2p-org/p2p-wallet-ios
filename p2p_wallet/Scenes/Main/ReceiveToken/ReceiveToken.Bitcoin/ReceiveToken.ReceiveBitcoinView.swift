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
    class ReceiveBitcoinView: BEView {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: ReceiveTokenBitcoinViewModelType
        
        // MARK: - Subviews
        private lazy var loadingView = BESpinnerView(size: 30, endColor: .h5887ff)
        private lazy var conditionView = ConditionView()
        private lazy var addressView = BEView()
        
        // MARK: - Initializers
        init(viewModel: ReceiveTokenBitcoinViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            viewModel.reload()
        }
        
        private func layout() {
            let stackView = UIStackView(
                axis: .vertical,
                spacing: 20,
                alignment: .fill,
                distribution: .fill
            ) {
                conditionView
                addressView
            }
            
            // add stackView
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
            
            // set min height to 200
            autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)
            
            // loadingView
            addSubview(loadingView)
            loadingView.autoCenterInSuperview()
            loadingView.animate()
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
            
            viewModel.conditionAcceptedDriver
                .drive(conditionView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.conditionAcceptedDriver
                .map {!$0}
                .drive(addressView.rx.isHidden)
                .disposed(by: disposeBag)
        }
    }
}

private class ConditionView: BEView {
    private lazy var receiveRenBTCSwitcher = UISwitch()
    private lazy var completeTxWithinTimeSwitcher = UISwitch()
    private lazy var confirmButton = WLButton.stepButton(type: .blue, label: L10n.showAddress)
    
    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
            UIStackView(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill) {
                UILabel(text: L10n.iWantToReceiveRenBTC, textSize: 15, weight: .semibold, numberOfLines: 0)
                receiveRenBTCSwitcher
            }
                .padding(.init(all: 20), cornerRadius: 12)
                .border(width: 1, color: .f6f6f8)
            
            UIStackView(axis: .horizontal, spacing: 12, alignment: .top, distribution: .fill) {
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
                .padding(.init(x: 16, y: 12), backgroundColor: .a3a5ba.withAlphaComponent(0.5))
            
            textBuilder(text: L10n.EachTransactionToThisDepositAddressTakesAbout60MinutesToComplete.forSecurityReasonsYouWillNeedToWaitFor6BlockConfirmationsBeforeYouCanMintRenBTCOnSolana)
            
            textBuilder(text: L10n.ifYouCannotCompleteThisTransactionWithinTheRequiredTimePleaseReturnAtALaterDate)
            
            textBuilder(text: L10n.ifYouDoNotFinishYourTransactionWithinThisPeriodSessionTimeFrameYouRiskLosingTheDeposits)
            
            UIStackView(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill) {
                UILabel(text: L10n.iCanCompleteThisTransactionWithinTime, textSize: 15, weight: .semibold, numberOfLines: 0)
                completeTxWithinTimeSwitcher
            }
                .padding(.init(all: 20), cornerRadius: 12)
                .border(width: 1, color: .f6f6f8)
            
            BEStackViewSpacing(20)
            
            confirmButton
        }
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
    
    private func textBuilder(text: String) -> UIStackView {
        UIStackView(axis: .horizontal, spacing: 10, alignment: .top, distribution: .fill) {
            UILabel(text: ".", textSize: 20)
            UILabel(text: text, textSize: 15, numberOfLines: 0)
        }
    }
}
