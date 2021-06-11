//
//  ReceiveToken.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import UIKit
import RxSwift

extension ReceiveToken {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ViewModel
        
        // MARK: - Subviews
        private lazy var addressLabel = UILabel(text: viewModel.output.pubkey, textSize: 15, weight: .semibold, textAlignment: .center)
            .lineBreakMode(.byTruncatingMiddle)
        
        private lazy var detailView = createDetailView()
        private lazy var showHideDetailButton = WLButton.stepButton(type: .gray, label: nil, labelColor: .a3a5ba)
            .onTap(viewModel, action: #selector(ViewModel.toggleIsShowingDetail))
        
        private lazy var directAddressHeaderLabel = UILabel(text: L10n.directAddress(viewModel.output.tokenWallet?.token.symbol ?? ""), textSize: 13, weight: .medium, textColor: .textSecondary)
        private lazy var mintAddressHeaderLabel = UILabel(text: L10n.mintAddress(viewModel.output.tokenWallet?.token.symbol ?? ""), textSize: 13, weight: .medium, textColor: .textSecondary)
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            backgroundColor = .vcBackground
            layout()
            bind()
        }
        
        // MARK: - Layout
        private func layout() {
            scrollView.contentInset.modify(dLeft: -.defaultPadding, dRight: -.defaultPadding)
            
            stackView.spacing = 30
            stackView.addArrangedSubviews {
                UILabel(text: L10n.scanOrCopyQRCode, textSize: 21, weight: .bold, numberOfLines: 0, textAlignment: .center)
                
                UIImageView(width: 207, height: 207, image: .receiveQrCodeFrame, tintColor: .f6f6f8.onDarkMode(.white))
                    .withCenteredChild(
                        QrCodeView(size: 190, coinLogoSize: 50)
                            .with(string: viewModel.output.pubkey)
                    )
                    .centeredHorizontallyView
                
                UIStackView(axis: .horizontal, spacing: 4, alignment: .fill, distribution: .fill, builder: {
                    addressLabel
                        .padding(.init(all: 20), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 4)
                    
                    UIImageView(width: 32, height: 32, image: .share, tintColor: .a3a5ba)
                        .onTap(viewModel, action: #selector(ViewModel.share))
                        .padding(.init(all: 12), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 4)
                })
                    .padding(.zero, cornerRadius: 12)
                    .padding(.init(x: 20, y: 0))
            }
            
            if viewModel.output.tokenWallet != nil {
                stackView.addArrangedSubview(detailView)
                stackView.addArrangedSubview(showHideDetailButton.padding(.init(x: 20, y: 0)))
            } else {
                stackView.addArrangedSubview(
                    UILabel(text: L10n.viewInExplorer, textSize: 17, weight: .medium, textColor: .a3a5ba, textAlignment: .center)
                        .onTap(viewModel, action: #selector(ViewModel.showSOLAddressInExplorer))
                        .centeredHorizontallyView
                        .padding(.init(x: 20, y: 9))
                )
            }
        }
        
        private func bind() {
            viewModel.output.isShowingDetail
                .map {!$0}
                .drive(detailView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.output.isShowingDetail
                .map {
                    $0 ? L10n.hideAddressDetail : L10n.showAddressDetail
                }
                .drive(showHideDetailButton.rx.title(for: .normal))
                .disposed(by: disposeBag)
        }
        
        private func createDetailView() -> UIStackView {
            UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
                UIView.separator(height: 1, color: .separator)
                
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    directAddressHeaderLabel
                    
                    UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                        UILabel(text: viewModel.output.tokenWallet?.pubkey, textSize: 15, weight: .medium, numberOfLines: 0)
                            .onTap(self, action: #selector(copyTokenPubKeyToClipboard))
                        
                        UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                            .padding(.init(all: 10), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                            .onTap(viewModel, action: #selector(ViewModel.showTokenPubkeyAddressInExplorer))
                    }
                }
                    .padding(.init(x: 20, y: 0))
                
                UIView.separator(height: 1, color: .separator)
                
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    mintAddressHeaderLabel
                    
                    UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                        UILabel(text: viewModel.output.tokenWallet?.token.address, textSize: 15, weight: .medium, numberOfLines: 0)
                            .onTap(self, action: #selector(copyTokenMintToClipboard))
                        
                        UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                            .padding(.init(all: 10), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                            .onTap(viewModel, action: #selector(ViewModel.showTokenMintAddressInExplorer))
                    }
                }
                    .padding(.init(x: 20, y: 0))
                
                UIView.separator(height: 1, color: .separator)
            }
        }
        
        @objc private func copyTokenPubKeyToClipboard() {
            guard let pubkey = viewModel.output.tokenWallet?.pubkey else {return}
            UIApplication.shared.copyToClipboard(pubkey, alert: false)
            
            let originalText = directAddressHeaderLabel.text
            directAddressHeaderLabel.text = L10n.addressCopied
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.directAddressHeaderLabel.text = originalText
            }
        }
        
        @objc private func copyTokenMintToClipboard() {
            guard let mint = viewModel.output.tokenWallet?.token.address else {return}
            UIApplication.shared.copyToClipboard(mint, alert: false)
            
            let originalText = mintAddressHeaderLabel.text
            mintAddressHeaderLabel.text = L10n.addressCopied
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.mintAddressHeaderLabel.text = originalText
            }
        }
    }
}
