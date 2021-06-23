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
        var isCopying = false
        
        // MARK: - Subviews
        private lazy var addressLabel = UILabel(text: viewModel.output.pubkey, textSize: 15, weight: .semibold, textAlignment: .center)
            .lineBreakMode(.byTruncatingMiddle)
        
        private lazy var detailView = createDetailView()
        private lazy var showHideDetailButton = WLButton.stepButton(type: .gray, label: nil, labelColor: .textSecondary)
            .onTap(viewModel, action: #selector(ViewModel.toggleIsShowingDetail))
        
        private lazy var directAddressHeaderLabel = UILabel(text: L10n.directAddress(viewModel.output.tokenWallet?.token.symbol ?? ""), textSize: 13, weight: .medium, textColor: .textSecondary)
        private lazy var mintAddressHeaderLabel = UILabel(text: L10n.mintAddress(viewModel.output.tokenWallet?.token.symbol ?? ""), textSize: 13, weight: .medium, textColor: .textSecondary)
        
        private var copiedToClipboardToastBottomConstraint: NSLayoutConstraint!
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
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
            scrollView.contentInset.modify(dLeft: -.defaultPadding, dRight: -.defaultPadding)
            
            stackView.spacing = 30
            stackView.addArrangedSubviews {
                UILabel(text: L10n.oneUnifiedAddressToReceiveSOLOrSPLTokens, textSize: 21, weight: .bold, numberOfLines: 0, textAlignment: .center)
                    .padding(.init(x: 20, y: 0))
                
                UIImageView(width: 207, height: 207, image: .receiveQrCodeFrame, tintColor: .f6f6f8.onDarkMode(.h8d8d8d))
                    .withCenteredChild(
                        QrCodeView(size: 190, coinLogoSize: 50)
                            .with(string: viewModel.output.pubkey)
                    )
                    .centeredHorizontallyView
                
                UIStackView(axis: .horizontal, spacing: 4, alignment: .fill, distribution: .fill) {
                    addressLabel
                        .padding(.init(all: 20), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 4)
                        .onTap(self, action: #selector(copyMainPubkeyToClipboard))
                    
                    UIImageView(width: 32, height: 32, image: .share, tintColor: .a3a5ba)
                        .onTap(viewModel, action: #selector(ViewModel.share))
                        .padding(.init(all: 12), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 4)
                }
                    .padding(.zero, cornerRadius: 12)
                    .padding(.init(x: 20, y: 0))
            }
            
            if viewModel.output.tokenWallet != nil {
                stackView.addArrangedSubviews {
                    detailView
                    showHideDetailButton.padding(.init(x: 20, y: 0))
                    BEStackViewSpacing(16)
                }
            } else {
                stackView.addArrangedSubviews {
                    UILabel(text: L10n.viewInExplorer, textSize: 17, weight: .medium, textColor: .textSecondary, textAlignment: .center)
                        .onTap(viewModel, action: #selector(ViewModel.showSOLAddressInExplorer))
                        .centeredHorizontallyView
                        .padding(.init(x: 20, y: 9))
                    BEStackViewSpacing(25)
                }
            }
            
            stackView.addArrangedSubviews {
                UIView.separator(height: 1, color: .separator)
                
                BEStackViewSpacing(10)
                
                UIView.allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice()
                    .padding(.init(x: 20, y: 0))
            }
            
            // Toast
            let copiedToClipboardToast = BERoundedCornerShadowView(shadowColor: .white.withAlphaComponent(0.15), radius: 16, offset: .zero, opacity: 1, cornerRadius: 12, contentInset: .init(x: 20, y: 10))
            copiedToClipboardToast.mainView.backgroundColor = .h202020.onDarkMode(.h202020)
            copiedToClipboardToast.stackView.addArrangedSubview(
                UILabel(text: L10n.addressCopiedToClipboard, textSize: 15, weight: .semibold, textColor: .white, numberOfLines: 0, textAlignment: .center)
            )
            copiedToClipboardToast.autoSetDimension(.width, toSize: 335)
            
            addSubview(copiedToClipboardToast)
            copiedToClipboardToast.autoAlignAxis(toSuperviewAxis: .vertical)
            copiedToClipboardToastBottomConstraint = copiedToClipboardToast.autoPinEdge(toSuperviewEdge: .bottom, withInset: -100)
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
            guard !isCopying, let pubkey = viewModel.output.tokenWallet?.pubkey else {return}
            isCopying = true
            
            viewModel.copyToClipboard(address: pubkey, logEvent: .receiveAddressCopy)
            
            let originalText = directAddressHeaderLabel.text
            directAddressHeaderLabel.text = L10n.addressCopied
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.directAddressHeaderLabel.text = originalText
                self?.isCopying = false
            }
        }
        
        @objc private func copyTokenMintToClipboard() {
            guard !isCopying, let mint = viewModel.output.tokenWallet?.token.address else {return}
            isCopying = true
            
            viewModel.copyToClipboard(address: mint, logEvent: .receiveAddressCopy)
            
            let originalText = mintAddressHeaderLabel.text
            mintAddressHeaderLabel.text = L10n.addressCopied
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.mintAddressHeaderLabel.text = originalText
                self?.isCopying = false
            }
        }
        
        @objc private func copyMainPubkeyToClipboard() {
            guard !isCopying else {return}
            isCopying = true
            
            viewModel.copyToClipboard(address: viewModel.output.pubkey, logEvent: .receiveAddressCopy)
            
            let addressLabelOriginalColor = addressLabel.textColor
            addressLabel.textColor = .h5887ff
            copiedToClipboardToastBottomConstraint.constant = -30
            
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.addressLabel.textColor = addressLabelOriginalColor
                    self?.copiedToClipboardToastBottomConstraint.constant = 100

                    UIView.animate(withDuration: 0.3) {
                        self?.layoutIfNeeded()
                        self?.isCopying = false
                    }
                }
            }
        }
    }
}
