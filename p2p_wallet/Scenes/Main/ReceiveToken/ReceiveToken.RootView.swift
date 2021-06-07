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
        private lazy var detailView = createDetailView()
        private lazy var showHideDetailButton = WLButton.stepButton(type: .gray, label: nil, labelColor: .a3a5ba)
            .onTap(viewModel, action: #selector(ViewModel.toggleIsShowingDetail))
        
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
                UIStackView(axis: .vertical, spacing: 39, alignment: .center, distribution: .fill, arrangedSubviews: [
                    UILabel(text: L10n.scanOrCopyQRCode, textSize: 17, weight: .semibold, numberOfLines: 0, textAlignment: .center),
                    QrCodeView(size: 208, coinLogoSize: 50)
                        .with(string: viewModel.output.pubkey),
                    UILabel(text: viewModel.output.pubkey, textSize: 15, weight: .semibold, numberOfLines: 0, textAlignment: .center)
                ])
                    .padding(.init(x: 20, y: 30), backgroundColor: .f6f6f8, cornerRadius: 12)
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
                    UILabel(text: L10n.directAddress(viewModel.output.tokenWallet?.token.symbol ?? ""), textSize: 13, weight: .medium, textColor: .textSecondary)
                    
                    UILabel(text: viewModel.output.pubkey, textSize: 15, weight: .medium)
                }
                    .padding(.init(x: 20, y: 0))
                
                UIView.separator(height: 1, color: .separator)
                
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    UILabel(text: L10n.mintAddress(viewModel.output.tokenWallet?.token.symbol ?? ""), textSize: 13, weight: .medium, textColor: .textSecondary)
                    
                    UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                        UILabel(text: viewModel.output.tokenWallet?.token.address, textSize: 15, weight: .medium, numberOfLines: 0)
                        
                        UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                            .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                            .onTap(viewModel, action: #selector(ViewModel.showInExplorer))
                    }
                }
                    .padding(.init(x: 20, y: 0))
                
                UIView.separator(height: 1, color: .separator)
            }
        }
    }
}
