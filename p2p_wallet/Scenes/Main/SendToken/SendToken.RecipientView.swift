//
//  SendToken.RecipientView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension SendToken {
    class RecipientView: BEView {
        // MARK: - Properties
        @Injected private var analyticsManager: AnalyticsManagerType
        private let disposeBag = DisposeBag()
        private let viewModel: SendTokenViewModelType
        
        // MARK: - Subviews
        private lazy var receiveAtLeastLabel = UILabel(text: nil, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 1, textAlignment: .right)
        private lazy var addressStackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .center, distribution: .fill, arrangedSubviews: [
            walletIconView, addressTextField, clearAddressButton, qrCodeImageView
        ])
        private lazy var walletIconView = UIImageView(width: 24, height: 24, image: .walletIcon, tintColor: .a3a5ba)
            .padding(.init(all: 10), backgroundColor: .white.onDarkMode(.h404040), cornerRadius: 12)
        private lazy var addressTextField: UITextField = {
            let textField = UITextField(height: 44, backgroundColor: .clear, placeholder: L10n.walletAddress, autocorrectionType: .none, autocapitalizationType: UITextAutocapitalizationType.none, spellCheckingType: .no, horizontalPadding: 8)
            textField.attributedPlaceholder = NSAttributedString(string: L10n.walletAddress, attributes: [.foregroundColor: UIColor.a3a5ba.onDarkMode(.h5887ff)])
            return textField
        }()
        private lazy var clearAddressButton = UIImageView(width: 24, height: 24, image: .closeFill, tintColor: UIColor.black.withAlphaComponent(0.6))
            .onTap(self, action: #selector(clearDestinationAddress))
        private lazy var qrCodeImageView = UIImageView(width: 35, height: 35, image: .scanQr3, tintColor: .a3a5ba)
            .onTap(self, action: #selector(scanQrCode))
        
        private lazy var checkingAddressValidityView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fill) {
            checkingAddressValidityIndicatorView
            
            UILabel(text: L10n.checkingAddressValidity, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
                .padding(.init(x: 20, y: 0))
        }
        
        private lazy var checkingAddressValidityIndicatorView = UIActivityIndicatorView()
        
        private lazy var noFundAddressView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill) {
            noFundAddressViewLabel
            
            UIView.defaultSeparator()
            
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill) {
                UILabel(text: L10n.imSureItSCorrect, textSize: 15, weight: .semibold)
                ignoreNoFundAddressSwitch
            }
            
        }
        
        private lazy var noFundAddressViewLabel = UILabel(text: L10n.ThisAddressHasNoFunds.areYouSureItSCorrect, textSize: 13, weight: .medium, textColor: .textSecondary, numberOfLines: 0)
        
        private lazy var ignoreNoFundAddressSwitch = UISwitch()
        
        // MARK: - Initializer
        init(viewModel: SendTokenViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
            checkingAddressValidityIndicatorView.startAnimating()
        }
        
        private func layout() {
            let contentView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill) {
                
                UIStackView(axis: .horizontal, spacing: 8, alignment: .top, distribution: .fill) {
                    UILabel(text: L10n.to, textSize: 15, weight: .semibold)
                    receiveAtLeastLabel
                }
                
                addressStackView
                    .padding(.init(all: 8), backgroundColor: .a3a5ba.onDarkMode(.h8d8d8d).withAlphaComponent(0.1), cornerRadius: 12)
                
                checkingAddressValidityView
                    
                noFundAddressView
            }
                .padding(.init(all: 16), cornerRadius: 12)
                .border(width: 1, color: .separator)
            
            addSubview(contentView)
            contentView.autoPinEdgesToSuperviewEdges()
        }
        
        private func bind() {
            // receive at least
            viewModel.renBTCInfoDriver.map {$0?.receiveAtLeast}
                .map {amount -> String? in
                    if let amount = amount {
                        return L10n.receiveAtLeast(amount.toString(maximumFractionDigits: 9), "BTC")
                    } else {
                        return nil
                    }
                }
                .drive(receiveAtLeastLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.renBTCInfoDriver.map {$0?.network != .bitcoin}
                .drive(receiveAtLeastLabel.rx.isHidden)
                .disposed(by: disposeBag)
            
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
            
            // receiver address
            viewModel.receiverAddressDriver
                .drive(addressTextField.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.receiverAddressDriver
                .map {[weak self] address in
                    guard let address = address else {return true}
                    return !address.matches(
                        oneOf: .publicKey, .bitcoinAddress(isTestnet: self?.viewModel.isTestNet() ?? true)
                    )
                }
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
                .withLatestFrom(viewModel.renBTCInfoDriver, resultSelector: {($0, $1)})
                .map { status, renBTCInfo -> String in
                    if renBTCInfo?.network == .bitcoin {
                        return L10n.areYouSureThatThisAddressIsValid(L10n.bitcoin)
                    } else {
                        if status == .fetchingError {
                            return L10n.ErrorCheckingAddressValidity.areYouSureItSCorrect
                        }
                        return L10n.ThisAddressHasNoFunds.areYouSureItSCorrect
                    }
                }
                .drive(noFundAddressViewLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.addressValidationStatusDriver
                .filter {$0 != .invalidIgnored}
                .map {_ in false}
                .drive(ignoreNoFundAddressSwitch.rx.isOn)
                .disposed(by: disposeBag)
            
            ignoreNoFundAddressSwitch.rx.isOn
                .map {$0 ? UIColor.textSecondary: UIColor.alert}
                .asDriver(onErrorJustReturn: .textSecondary)
                .drive(noFundAddressViewLabel.rx.textColor)
                .disposed(by: disposeBag)
        }
    }
}

private extension SendToken.RecipientView {
    @objc func clearDestinationAddress() {
        viewModel.clearDestinationAddress()
    }
    
    @objc func scanQrCode() {
        analyticsManager.log(event: .sendScanQrClick)
        analyticsManager.log(event: .scanQrOpen(fromPage: "send"))
        viewModel.navigate(to: .scanQrCode)
    }
}
