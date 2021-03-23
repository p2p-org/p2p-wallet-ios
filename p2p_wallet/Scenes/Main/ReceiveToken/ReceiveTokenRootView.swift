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
    private lazy var symbolLabel = UILabel(text: "<Symbol>", weight: .medium)
    private lazy var shortAddresslabel = UILabel(text: "<address>", textSize: 13, textColor: .a3a5ba)
    private lazy var titleLabel = UILabel(text: "<Your address>", textSize: 17, weight: .semibold, numberOfLines: 0, textAlignment: .center)
    private lazy var qrCodeView = QrCodeView(size: 208, coinLogoSize: 50)
    private lazy var addressLabel = UILabel(text: "<address>", textSize: 13, numberOfLines: 0, textAlignment: .center)
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
                UIImageView(width: 13, height: 8, image: .downArrow, tintColor: .a3a5ba)
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
                UILabel(text: L10n.mintAddress, weight: .semibold),
                UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                    mintAddressLabel,
                    UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                        .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                        .onTap(viewModel, action: #selector(ReceiveTokenViewModel.showMintInExplorer))
                ])
            ])
        ])
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
            .map {wallet -> String? in
                if let pubkey = wallet?.pubkey {
                    return pubkey.prefix(4) + "..." + pubkey.prefix(4)
                }
                return nil
            }
            .drive(shortAddresslabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver
            .map { wallet -> String? in
                if let symbol = wallet?.symbol {
                    return L10n.yourPublicAddress(symbol)
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
        
        walletDriver.map {$0?.pubkey}
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        walletDriver.map {$0?.mintAddress}
            .drive(mintAddressLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
