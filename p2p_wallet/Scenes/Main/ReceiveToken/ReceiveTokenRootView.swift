//
//  ReceiveTokenRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import UIKit
import RxSwift

class ReceiveTokenRootView: ScrollableVStackRootView, LoadableView {
    var loadingViews: [UIView] {[
        coinLogoImageView,
        symbolLabel,
        shortAddresslabel,
        titleLabel,
        qrCodeView,
        addressLabel,
        mintAddressLabel
    ]}
    
    // MARK: - Constants
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    let viewModel: ReceiveTokenViewModel
    
    // MARK: - Subviews
    private lazy var coinLogoImageView = CoinLogoImageView(width: 45, height: 45, cornerRadius: 12)
    private lazy var symbolLabel = UILabel(text: "<Symbol>", weight: .semibold)
    private lazy var shortAddresslabel = UILabel(text: "<address>", textSize: 13, textColor: .a3a5ba, numberOfLines: 0)
//        .onTap(viewModel, action: #selector(ReceiveTokenViewModel.createWallet))
    private lazy var titleLabel = UILabel(text: "<Your address>", textSize: 17, weight: .semibold, numberOfLines: 0, textAlignment: .center)
    private lazy var qrCodeView = QrCodeView(size: 208, coinLogoSize: 50)
    private lazy var addWalletButton = WLAddTokenButton()
        .onTap(viewModel, action: #selector(ReceiveTokenViewModel.createWallet))
    private lazy var addressLabel = UILabel(text: "<address>", textSize: 13, numberOfLines: 0, textAlignment: .center)
    private lazy var mintAddressTitleLabel = UILabel(text: L10n.mintAddress, weight: .semibold)
    private lazy var mintAddressLabel = UILabel(text: "<mint address>", textSize: 13, textColor: .a3a5ba, numberOfLines: 0)
    
    // MARK: - Initializers
    init(viewModel: ReceiveTokenViewModel) {
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
        viewModel.feeSubject.reload()
    }
    
    // MARK: - Layout
    private func layout() {
        stackView.spacing = 20
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                coinLogoImageView,
                UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    symbolLabel,
                    shortAddresslabel
                ]),
                UIImageView(width: 13, height: 8, image: .downArrowLight, tintColor: .a3a5ba)
            ])
                .padding(UIEdgeInsets(all: 8).modifying(dRight: 8), backgroundColor: .f6f6f8, cornerRadius: 12)
                .onTap(viewModel, action: #selector(ReceiveTokenViewModel.selectWallet)),
            UIStackView(axis: .vertical, spacing: 39, alignment: .center, distribution: .fill, arrangedSubviews: [
                titleLabel,
                qrCodeView,
                addressLabel
            ])
                .padding(.init(x: 20, y: 30), backgroundColor: .f6f6f8, cornerRadius: 12),
            UIView.separator(height: 1, color: .separator),
            UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
                mintAddressTitleLabel,
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                    mintAddressLabel,
                    UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                        .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                        .onTap(viewModel, action: #selector(ReceiveTokenViewModel.showMintInExplorer))
                ])
            ])
        ])
        
        scrollView.contentView.addSubview(addWalletButton)
        addWalletButton.autoPinEdge(.leading, to: .leading, of: stackView, withOffset: 20)
        addWalletButton.autoPinEdge(.trailing, to: .trailing, of: stackView, withOffset: -20)
        addWalletButton.autoPinEdge(.bottom, to: .bottom, of: qrCodeView, withOffset: 24)
    }
    
    private func bind() {
        let walletDriver = viewModel.wallet
            .asDriver()
            .asDriver(onErrorJustReturn: nil)
        
        walletDriver
            .drive(onNext: {[weak self] wallet in
                self?.coinLogoImageView.setUp(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        walletDriver
            .map {$0?.symbol}
            .drive(symbolLabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver
            .map {wallet -> String? in
                if let pubkey = wallet?.pubkey {
                    return pubkey.prefix(4) + "..." + pubkey.suffix(4)
                } else {
                    return L10n.addTokenToSeeWalletAddress
                }
            }
            .drive(shortAddresslabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver
            .map {$0?.pubkey == nil ? UIColor.h5887ff: UIColor.a3a5ba}
            .drive(shortAddresslabel.rx.textColor)
            .disposed(by: disposeBag)
        
//        walletDriver
//            .map {$0?.pubkey == nil}
//            .drive(shortAddresslabel.rx.isUserInteractionEnabled)
//            .disposed(by: disposeBag)
        
        walletDriver
            .map { wallet -> String? in
                if let symbol = wallet?.symbol {
                    if wallet?.pubkey != nil {
                        return L10n.yourPublicAddress(symbol)
                    }
                    return L10n.toSeeWalletAddressYouMustAddThisTokenToYourTokenList(symbol)
                }
                return nil
            }
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver
            .drive(onNext: {[weak self] wallet in
                self?.qrCodeView.setUp(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        walletDriver
            .map {$0?.pubkey == nil ? 0.05: 1}
            .drive(qrCodeView.rx.alpha)
            .disposed(by: disposeBag)
        
        walletDriver
            .map {$0?.pubkey != nil}
            .drive(addWalletButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        let hasEnoughSOLToPay = Observable.combineLatest(
            viewModel.repository
                .dataDidChange
                .map {[weak self] in
                    self?.viewModel.repository.solWallet?.amount ?? 0
                },
            viewModel.feeSubject
                .observable
                .map {[weak self] _ in self?.viewModel.feeSubject.value ?? 0}
        )
            .map {$0 > $1}
            .asDriver(onErrorJustReturn: true)
            
        hasEnoughSOLToPay
            .drive(addWalletButton.rx.isActive)
            .disposed(by: disposeBag)
        
        hasEnoughSOLToPay
            .map {$0 ? L10n.addToken: L10n.addToken + " (\(L10n.insufficientFunds.lowercased())"}
            .drive(addWalletButton.titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver
            .drive(onNext: { [weak self] in
                guard let wallet = $0 else {return}
                self?.addWalletButton.setUp(with: wallet, showLoading: false)
            })
            .disposed(by: disposeBag)
            
        addWalletButton.setUp(feeSubject: viewModel.feeSubject)
        
        walletDriver.map {
            if let pubkey = $0?.pubkey {
                return pubkey
            } else if $0?.creatingError != nil {
                return L10n.WeCouldnTAddATokenToYourWallet.checkYourInternetConnectionAndTryAgain
            } else {
                return L10n.allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice
            }
        }
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver.map {$0?.pubkey == nil ? ($0?.creatingError == nil ? UIColor.a3a5ba: UIColor.alert): UIColor.textBlack}
            .drive(addressLabel.rx.textColor)
            .disposed(by: disposeBag)
        
        walletDriver.map {L10n.mintAddress($0?.symbol ?? "")}
            .drive(mintAddressTitleLabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver.map {$0?.mintAddress}
            .drive(mintAddressLabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver.map {$0?.isBeingCreated == true}
            .drive(onNext: {isBeingCreated in
                if isBeingCreated {
                    UIApplication.shared.showLoadingIndicatorView()
                } else {
                    UIApplication.shared.hideLoadingIndicatorView()
                }
            })
            .disposed(by: disposeBag)
    }
}
