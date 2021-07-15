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
        private lazy var tokenCountLabel = UILabel(text: "+", textSize: 12, weight: .semibold, textColor: .white)
        private lazy var addressLabel = UILabel(text: viewModel.output.pubkey, textSize: 15, weight: .semibold, textAlignment: .center)
            .lineBreakMode(.byTruncatingMiddle)
        
        private lazy var detailView = createDetailView()
        private lazy var showHideDetailButton = WLButton.stepButton(type: .gray, label: nil, labelColor: .a3a5baStatic.onDarkMode(.white))
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
            layout()
            bind()
        }
        
        // MARK: - Layout
        private func layout() {
            scrollView.contentInset.modify(dLeft: -.defaultPadding, dRight: -.defaultPadding)
            
            stackView.spacing = 20
            stackView.addArrangedSubviews {
                UILabel(text: L10n.oneUnifiedAddressToReceiveSOLOrSPLTokens, textSize: 21, weight: .bold, numberOfLines: 0, textAlignment: .center)
                    .padding(.init(x: 20, y: 0))
                
                UIImageView(width: 207, height: 207, image: .receiveQrCodeFrame, tintColor: .f6f6f8.onDarkMode(.h8d8d8d))
                    .withCenteredChild(
                        QrCodeView(size: 190, coinLogoSize: 50)
                            .with(string: viewModel.output.pubkey)
                    )
                    .centeredHorizontallyView
                
                UIView(forAutoLayout: ())
                    .withModifier {[unowned self] view in
                        let imageView = UIImageView(width: 92, height: 32, image: .tokenExampleStack)
                        view.addSubview(imageView)
                        imageView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)
                        let wrapperView = self.tokenCountLabel
                            .padding(.init(x: 6, y: 4), backgroundColor: .h202020.withAlphaComponent(0.8), cornerRadius: 12)
                        view.addSubview(wrapperView)
                        wrapperView.autoPinEdge(toSuperviewEdge: .trailing)
                        wrapperView.autoAlignAxis(toSuperviewAxis: .horizontal)
                        wrapperView.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: -12)
                        return view
                    }
                    .onTap(viewModel, action: #selector(ViewModel.showHelp))
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
                UIView.defaultSeparator()
                
                BEStackViewSpacing(10)
                
                UIView.allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice()
                    .padding(.init(x: 20, y: 0))
            }
        }
        
        private func bind() {
            viewModel.output.tokensCount
                .map {"+\($0 - 4)"}
                .drive(tokenCountLabel.rx.text)
                .disposed(by: disposeBag)
            
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
                UIView.defaultSeparator()
                
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
                
                UIView.defaultSeparator()
                
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
                
                UIView.defaultSeparator()
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
            
            UIApplication.shared.showToast(
                message: "✅ " + L10n.addressCopiedToClipboard
            ) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.addressLabel.textColor = addressLabelOriginalColor
                    self?.isCopying = false
                }
            }
        }
    }
}
