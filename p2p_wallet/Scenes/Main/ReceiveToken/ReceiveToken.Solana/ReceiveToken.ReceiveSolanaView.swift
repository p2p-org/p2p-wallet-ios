//
//  ReceiveToken.ReceiveSolanaView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension ReceiveToken {
    class ReceiveSolanaView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ReceiveTokenSolanaViewModelType
        var isCopying = false
        
        // MARK: - Subviews
        private lazy var tokenCountLabel = UILabel(text: "+", textSize: 12, weight: .semibold, textColor: .white)
        private lazy var addressLabel = UILabel(text: viewModel.pubkey, textSize: 15, weight: .semibold, textAlignment: .center)
            .lineBreakMode(.byTruncatingMiddle)
        private lazy var nameLabel: UIView = {
            guard let username = viewModel.getUsername(),
                  let nameWithDomain = viewModel.getUsername()?.withNameServiceDomain() else { return UIView() }
            
            let text = NSMutableAttributedString(string: nameWithDomain)
            text.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: username.count, length: text.length - username.count))
            
            let label = UILabel(textSize: 20, weight: .semibold, textAlignment: .center)
            label.attributedText = text
            return label
        }()
        
        private lazy var detailView = createDetailView()
        private lazy var showHideDetailButton = WLButton.stepButton(type: .gray, label: nil, labelColor: .a3a5baStatic.onDarkMode(.white))
            .onTap(self, action: #selector(toggleIsShowingDetail))
        
        private lazy var directAddressHeaderLabel = UILabel(text: L10n.directAddress(viewModel.tokenWallet?.token.symbol ?? ""), textSize: 13, weight: .medium, textColor: .textSecondary)
        private lazy var mintAddressHeaderLabel = UILabel(text: L10n.mintAddress(viewModel.tokenWallet?.token.symbol ?? ""), textSize: 13, weight: .medium, textColor: .textSecondary)
        
        fileprivate let copyButton: UIButton = UIButton.text(text: L10n.copy, image: .copyIcon, tintColor: .h5887ff)
        fileprivate let shareButton: UIButton = UIButton.text(text: L10n.share, image: .share2, tintColor: .h5887ff)
        fileprivate let saveButton: UIButton = UIButton.text(text: L10n.save, image: .imageIcon, tintColor: .h5887ff)
        
        // MARK: - Initializers
        init(viewModel: ReceiveTokenSolanaViewModelType) {
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
            let stackView = UIStackView(
                axis: .vertical,
                spacing: 24,
                alignment: .fill,
                distribution: .fill
            ) {
                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                    UILabel(text: L10n.whichCryptocurrenciesCanIUse, textSize: 15, weight: .semibold, numberOfLines: 0)
                    UIImageView(width: 24, height: 24, image: .questionMarkCircle, tintColor: .a3a5ba)
                        .onTap(self, action: #selector(showHelp))
                }
                    .padding(.init(x: 20, y: 22.5), cornerRadius: 12)
                    .border(width: 1, color: .defaultBorder)
                
                UIStackView(axis: .vertical, alignment: .fill) {
                    nameLabel.padding(.init(only: .top, inset: 26))
                    
                    QrCodeView(size: 190, coinLogoSize: 32)
                        .with(string: viewModel.pubkey, token: viewModel.tokenWallet?.token)
                        .autoAdjustWidthHeightRatio(1)
                        .padding(.init(x: 50, y: 33))
                    
                    UIView.defaultSeparator()
                    
                    UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually) {
                        copyButton
                        shareButton
                        saveButton
                    }.padding(.init(x: 0, y: 4))
                }.border(width: 1, color: .f2f2f7)
                    .box(cornerRadius: 12)
                    .shadow(color: .black, alpha: 0.05, y: 1, blur: 8)
                    .margin(.init(x: 0, y: 18))
                
                ReceiveToken.copyAndShareableField(
                    label: addressLabel,
                    copyTarget: self,
                    copySelector: #selector(copyMainPubkeyToClipboard),
                    shareTarget: self,
                    shareSelector: #selector(sharePubkey)
                )
            }

//            if viewModel.getUsername() != nil {
//                var index = 2
//                stackView.insertArrangedSubviews(at: &index) {
//                    ReceiveToken.copyAndShareableField(
//                        label: nameLabel,
//                        copyTarget: self,
//                        copySelector: #selector(copyNameToClipboard),
//                        shareTarget: self,
//                        shareSelector: #selector(shareName)
//                    )
//
//                    BEStackViewSpacing(8)
//                }
//            }
            
            if viewModel.tokenWallet != nil {
                stackView.addArrangedSubviews {
                    detailView
                    showHideDetailButton
                }
            } else {
                stackView.addArrangedSubviews {
                    BEStackViewSpacing(50)
                    ReceiveToken.viewInExplorerButton(
                        title: L10n.viewInExplorer(L10n.solana),
                        target: self,
                        selector: #selector(showSolAddressInExplorer)
                    )
                }
            }
            
            // add stackView
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 0))
        }
        
        private func bind() {
            viewModel.tokensCountDriver
                .map { "+\($0 - 4)" }
                .drive(tokenCountLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.isShowingDetailDriver
                .map { !$0 }
                .drive(detailView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.isShowingDetailDriver
                .map {
                    $0 ? L10n.hideAddressDetail : L10n.showAddressDetail
                }
                .drive(showHideDetailButton.rx.title(for: .normal))
                .disposed(by: disposeBag)
        }
        
        private func createDetailView() -> UIStackView {
            UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
                UIView.defaultSeparator()
                
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    directAddressHeaderLabel
                    
                    UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                        UILabel(text: viewModel.tokenWallet?.pubkey, textSize: 15, weight: .medium, numberOfLines: 0)
                            .onTap(self, action: #selector(copyTokenPubKeyToClipboard))
                        
                        UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                            .padding(.init(all: 10), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                            .onTap(self, action: #selector(showTokenPubkeyAddressInExplorer))
                    }
                }
                
                UIView.defaultSeparator()
                
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    mintAddressHeaderLabel
                    
                    UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                        UILabel(text: viewModel.tokenWallet?.token.address, textSize: 15, weight: .medium, numberOfLines: 0)
                            .onTap(self, action: #selector(copyTokenMintToClipboard))
                        
                        UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                            .padding(.init(all: 10), backgroundColor: .a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                            .onTap(self, action: #selector(showTokenMintAddressInExplorer))
                    }
                }
                
                UIView.defaultSeparator()
            }
        }
        
        @objc func showHelp() {
            viewModel.showHelp()
        }
        
        @objc func toggleIsShowingDetail() {
            viewModel.toggleIsShowingDetail()
        }
        
        @objc func showSolAddressInExplorer() {
            viewModel.showSOLAddressInExplorer()
        }
        
        @objc func sharePubkey() {
            viewModel.sharePubkey()
        }
        
        @objc func shareName() {
            viewModel.shareName()
        }
        
        @objc func showTokenPubkeyAddressInExplorer() {
            viewModel.showTokenPubkeyAddressInExplorer()
        }
        
        @objc func showTokenMintAddressInExplorer() {
            viewModel.showTokenMintAddressInExplorer()
        }
        
        @objc private func copyTokenPubKeyToClipboard() {
            guard !isCopying, let pubkey = viewModel.tokenWallet?.pubkey else { return }
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
            guard !isCopying, let mint = viewModel.tokenWallet?.token.address else { return }
            isCopying = true
            
            viewModel.copyToClipboard(address: mint, logEvent: .receiveAddressCopy)
            
            let originalText = mintAddressHeaderLabel.text
            mintAddressHeaderLabel.text = L10n.addressCopied
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.mintAddressHeaderLabel.text = originalText
                self?.isCopying = false
            }
        }
        
        @objc private func copyNameToClipboard() {
//            copyToClipboard(viewModel.getUsername()?.withNameServiceDomain() ?? "", event: .receiveNameCopy, onLabel: nameLabel, message: L10n.nameCopiedToClipboard)
        }
        
        @objc private func copyMainPubkeyToClipboard() {
            copyToClipboard(viewModel.pubkey, event: .receiveAddressCopy, onLabel: addressLabel, message: L10n.addressCopiedToClipboard)
        }
        
        private func copyToClipboard(_ textToCopy: String, event: AnalyticsEvent, onLabel label: UILabel, message: String) {
            guard !isCopying else { return }
            isCopying = true
            
            viewModel.copyToClipboard(address: textToCopy, logEvent: event)
            
            let originalColor = label.textColor
            label.textColor = .h5887ff
            
            UIApplication.shared.showToast(
                message: "✅ " + message
            ) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self, weak label] in
                    label?.textColor = originalColor
                    self?.isCopying = false
                }
            }
        }
    }
}
