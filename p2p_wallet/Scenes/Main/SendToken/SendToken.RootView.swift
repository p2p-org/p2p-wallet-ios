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
        private lazy var feeLabel = UILabel(textSize: 15, weight: .medium)
        
        lazy var addressStackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
            walletIconView, addressTextField, clearAddressButton, qrCodeImageView
        ])
        lazy var walletIconView = UIImageView(width: 24, height: 24, image: .walletIcon, tintColor: .a3a5ba)
            .padding(.init(all: 10), backgroundColor: .white.onDarkMode(.h404040), cornerRadius: 12)
        lazy var addressTextField: UITextField = {
            let textField = UITextField(height: 44, backgroundColor: .clear, placeholder: L10n.walletAddress, autocorrectionType: .none, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .no, horizontalPadding: 8)
            textField.attributedPlaceholder = NSAttributedString(string: L10n.walletAddress, attributes: [.foregroundColor: UIColor.a3a5ba.onDarkMode(.h5887ff)])
            return textField
        }()
        lazy var clearAddressButton = UIImageView(width: 24, height: 24, image: .closeFill, tintColor: UIColor.black.withAlphaComponent(0.6))
            .onTap(self, action: #selector(clearDestinationAddress))
        lazy var qrCodeImageView = UIImageView(width: 35, height: 35, image: .scanQr3, tintColor: .a3a5ba)
            .onTap(self, action: #selector(scanQrCode))
        lazy var errorLabel = UILabel(text: " ", textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
        
        lazy var feeInfoButton = UIImageView(width: 16.67, height: 16.67, image: .infoCircle, tintColor: .a3a5ba)
            .onTap(self, action: #selector(showFeeInfo))
        
        lazy var checkingAddressValidityView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fill) {
            checkingAddressValidityIndicatorView
            
            UILabel(text: L10n.checkingAddressValidity, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
                .padding(.init(x: 20, y: 0))
        }
        
        lazy var checkingAddressValidityIndicatorView = UIActivityIndicatorView()
        
        lazy var noFundAddressView = UIStackView(axis: .vertical, spacing: 12, alignment: .fill, distribution: .fill) {
            noFundAddressViewLabel
                .padding(.init(x: 20, y: 0))
            
            UIView.defaultSeparator()
            
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill) {
                UILabel(text: L10n.imSureItSCorrect, textSize: 15, weight: .semibold)
                ignoreNoFundAddressSwitch
            }
                .padding(.init(x: 20, y: 0))
            
        }
            .padding(.init(x: 0, y: 12), backgroundColor: .fbfbfd, cornerRadius: 12)
        
        lazy var noFundAddressViewLabel = UILabel(text: L10n.ThisAddressHasNoFunds.areYouSureItSCorrect, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
        
        lazy var ignoreNoFundAddressSwitch = UISwitch()
        
        lazy var sendButton = WLButton.stepButton(type: .blue, label: L10n.sendNow)
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
                
                UIView.createSectionView(
                    title: L10n.transferFee,
                    contentView: feeLabel,
                    rightView: feeInfoButton,
                    addSeparatorOnTop: true
                )
                
                UIView.defaultSeparator()
                
                UILabel(text: L10n.sendTo, weight: .bold)
                addressStackView
                    .padding(.init(all: 8), backgroundColor: .a3a5ba.onDarkMode(.h8d8d8d).withAlphaComponent(0.1), cornerRadius: 12)
                
                BEStackViewSpacing(10)
                
                errorLabel
                
                checkingAddressValidityView
                noFundAddressView
                
                BEStackViewSpacing(30)
                
                UIView.defaultSeparator()
                
                sendButton
                
                BEStackViewSpacing(16)
                
                UILabel(text: L10n.sendSOLOrAnySPLTokensOnOneAddress, textSize: 14, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
                    .padding(.init(x: 20, y: 0))
                
                BEStackViewSpacing(16)
                
                UIView.defaultSeparator()
                
                BEStackViewSpacing(10)
                
                UIView.allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice()
            }
            
            feeInfoButton.isHidden = !Defaults.useFreeTransaction
            
            checkingAddressValidityIndicatorView.startAnimating()
        }
        
        private func bind() {
            // address
            addressTextField.rx.text
                .skip(while: {$0?.isEmpty == true})
                .subscribe(onNext: {[weak self] address in
                    self?.viewModel.enterWalletAddress(address)
                })
                .disposed(by: disposeBag)
            
            addressTextField.rx.controlEvent([.editingDidEnd])
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.analyticsManager.log(event: .sendAddressKeydown)
                })
                .disposed(by: disposeBag)
            
            // ignore no fund address
            ignoreNoFundAddressSwitch.rx.isOn
                .skip(while: {!$0})
                .subscribe(onNext: {[weak self] isIgnored in
                    self?.viewModel.ignoreEmptyBalance(isIgnored)
                })
                .disposed(by: disposeBag)
            
            // price labels
            viewModel.currentWalletDriver
                .map {"\(Defaults.fiat.symbol)\(($0?.priceInCurrentFiat ?? 0).toString(maximumFractionDigits: 9)) \(L10n.per) \($0?.token.symbol ?? "")"}
                .drive(priceLabel.rx.text)
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
            
            // receiver address
            viewModel.receiverAddressDriver
                .drive(addressTextField.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.receiverAddressDriver
                .map {!NSRegularExpression.publicKey.matches($0 ?? "")}
                .drive(walletIconView.rx.isHidden)
                .disposed(by: disposeBag)
            
            let destinationAddressInputEmpty = viewModel.receiverAddressDriver
                .map {$0 == nil || $0!.isEmpty}
            
            destinationAddressInputEmpty
                .drive(clearAddressButton.rx.isHidden)
                .disposed(by: disposeBag)
            
            let destinationAddressInputNotEmpty = destinationAddressInputEmpty
                .map {!$0}
            
            destinationAddressInputNotEmpty
                .drive(qrCodeImageView.rx.isHidden)
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
            
            // no fund
            viewModel.addressValidationStatusDriver
                .map {$0 == .uncheck || $0 == .valid || $0 == .fetching}
                .drive(noFundAddressView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.addressValidationStatusDriver
                .map {$0 != .fetching}
                .drive(checkingAddressValidityView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.addressValidationStatusDriver
                .map {
                    if $0 == .fetchingError {
                        return L10n.ErrorCheckingAddressValidity.areYouSureItSCorrect
                    }
                    return L10n.ThisAddressHasNoFunds.areYouSureItSCorrect
                }
                .drive(noFundAddressViewLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.addressValidationStatusDriver
                .filter {$0 != .invalidIgnored}
                .map {_ in false}
                .drive(ignoreNoFundAddressSwitch.rx.isOn)
                .disposed(by: disposeBag)
            
            // send button
            viewModel.isValidDriver
                .drive(sendButton.rx.isEnabled)
                .disposed(by: disposeBag)
        }
    }
}

private extension SendToken.RootView {
    @objc func clearDestinationAddress() {
        viewModel.clearDestinationAddress()
    }
    
    @objc func scanQrCode() {
        analyticsManager.log(event: .sendScanQrClick)
        analyticsManager.log(event: .scanQrOpen(fromPage: "send"))
        viewModel.navigate(to: .scanQrCode)
    }
    
    @objc func showFeeInfo() {
        viewModel.navigate(to: .feeInfo)
    }
    
    @objc func authenticateAndSend() {
        viewModel.authenticateAndSend()
    }
}
