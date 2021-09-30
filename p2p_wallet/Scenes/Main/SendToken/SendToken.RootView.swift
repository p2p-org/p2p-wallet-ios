//
//  SendRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension SendToken {
    class RootView: ScrollableVStackRootView {
        // MARK: - Dependencies
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let viewModel: SendTokenViewModelType
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private lazy var walletView = WalletView(viewModel: viewModel)
        private lazy var priceLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var renBTCNetworkSection = UIView.createSectionView(
            title: L10n.destinationNetwork,
            contentView: renBTCNetworkLabel,
            addSeparatorOnTop: true
        )
            .onTap(self, action: #selector(chooseBTCNetwork))
        private lazy var renBTCNetworkLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var feeLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var recipientView = RecipientView(viewModel: viewModel)
        
        private lazy var errorLabel = UILabel(text: " ", textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
        
        private lazy var feeInfoButton = UIImageView(width: 20, height: 20, image: .infoCircle, tintColor: .a3a5ba)
            .onTap(self, action: #selector(showFeeInfo))
        
        private lazy var sendButton = WLButton.stepButton(type: .blue, label: L10n.sendNow)
            .onTap(self, action: #selector(authenticateAndSend))
        
        // MARK: - Initializers
        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        // MARK: - Layout
        private func layout() {
            stackView.spacing = 20
            stackView.addArrangedSubviews {
                walletView
                
                UIView.createSectionView(
                    title: L10n.currentPrice,
                    contentView: priceLabel,
                    rightView: nil,
                    addSeparatorOnTop: false
                )
                
                renBTCNetworkSection
                
                UIView.createSectionView(
                    title: L10n.transferFee,
                    contentView: feeLabel,
                    rightView: feeInfoButton,
                    addSeparatorOnTop: true
                )
                
                recipientView
                
                errorLabel
                
                sendButton
                
                BEStackViewSpacing(16)
                
                UILabel(text: L10n.sendSOLOrAnySPLTokensOnOneAddress, textSize: 14, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
                    .padding(.init(x: 20, y: 0))
            }
            
            feeInfoButton.isHidden = !Defaults.useFreeTransaction
        }
        
        private func bind() {
            // price labels
            viewModel.currentWalletDriver
                .map {"\(Defaults.fiat.symbol)\(($0?.priceInCurrentFiat ?? 0).toString(maximumFractionDigits: 9)) \(L10n.per) \($0?.token.symbol ?? "")"}
                .drive(priceLabel.rx.text)
                .disposed(by: disposeBag)
            
            // renBTC
            viewModel.renBTCInfoDriver
                .map {$0 == nil}
                .drive(renBTCNetworkSection.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.renBTCInfoDriver
                .map {$0?.network == .bitcoin}
                .drive(feeInfoButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.renBTCInfoDriver
                .map {$0?.network.rawValue.uppercaseFirst.localized()}
                .drive(renBTCNetworkLabel.rx.text)
                .disposed(by: disposeBag)
            
            // fee
            viewModel.feeDriver
                .drive(feeLabel.rx.loadableText(onLoaded: { fee in
                    let fee = fee ?? 0
                    if fee == 0 {
                        return L10n.free
                    }
                    
                    return "\(fee.toString(maximumFractionDigits: 9)) SOL"
                }))
                .disposed(by: disposeBag)
            
            // error
            viewModel.errorDriver
                .map {
                    if $0 == L10n.insufficientFunds || $0 == L10n.amountIsNotValid
                    {
                        return nil
                    }
                    return $0
                }
                .asDriver(onErrorJustReturn: nil)
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)
            
            // send button
            viewModel.isValidDriver
                .drive(sendButton.rx.isEnabled)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.amountDriver.map {($0 == nil || $0 == 0)},
                viewModel.receiverAddressDriver.map {address in
                    guard let address = address else {return true}
                    return address.isEmpty
                }
            )
                .map(generateSendButtonText)
                .drive(sendButton.rx.title())
                .disposed(by: disposeBag)
        }
    }
}

private extension SendToken.RootView {
    @objc func showFeeInfo() {
        viewModel.navigate(to: .feeInfo)
    }
    
    @objc func chooseBTCNetwork() {
        viewModel.navigateToSelectBTCNetwork()
    }
    
    @objc func authenticateAndSend() {
        viewModel.authenticateAndSend()
    }
}

private func generateSendButtonText(
    isAmountNil: Bool,
    isRecipientNil: Bool
) -> String {
    if isAmountNil {
        return L10n.enterTheAmount
    }
    
    if isRecipientNil {
        return L10n.enterTheRecipientSAddress
    }
    
    return L10n.sendNow
}
