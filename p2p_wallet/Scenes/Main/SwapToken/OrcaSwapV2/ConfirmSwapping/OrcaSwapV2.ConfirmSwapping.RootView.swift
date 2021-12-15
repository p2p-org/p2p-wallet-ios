//
//  OrcaSwapV2.ConfirmSwapping.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension OrcaSwapV2.ConfirmSwapping {
    final class RootView: ScrollableVStackRootView {
        // MARK: - Properties
        private let viewModel: OrcaSwapV2ConfirmSwappingViewModelType
        
        // MARK: - Subviews
        private lazy var bannerView = UIView.greyBannerView(axis: .horizontal, spacing: 12, alignment: .top) {
            UILabel(
                text: L10n.BeSureAllDetailsAreCorrectBeforeConfirmingTheTransaction
                    .onceConfirmedItCannotBeReversed,
                textSize: 15,
                numberOfLines: 0
            )
            UIView.closeBannerButton()
                .onTap(self, action: #selector(closeBannerButtonDidTouch))
        }
        
        // MARK: - Initializers
        init(viewModel: OrcaSwapV2ConfirmSwappingViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            scrollView.contentInset = .init(top: 8, left: 18, bottom: 18, right: 18)
            setUp()
        }
        
        private func setUp() {
            stackView.addArrangedSubviews {
                UIView.floatingPanel(contentInset: .init(x: 8, y: 16), axis: .horizontal, spacing: 8, alignment: .center, distribution: .equalCentering) {
                    WalletView(viewModel: viewModel, type: .source)
                        .centered(.horizontal)
                    
                    UIImageView(width: 11.88, height: 9.74, image: .arrowForward, tintColor: .h8e8e93)
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .padding(.init(all: 10), backgroundColor: .fafafc, cornerRadius: 12)
                        .withContentHuggingPriority(.required, for: .horizontal)
                    
                    WalletView(viewModel: viewModel, type: .destination)
                        .centered(.horizontal)
                }
            }
            
            if !viewModel.isBannerForceClosed() {
                stackView.insertArrangedSubview(bannerView, at: 0)
            }
        }
        
        // MARK: - Action
        @objc private func closeBannerButtonDidTouch() {
            UIView.animate(withDuration: 0.3) {
                self.bannerView.isHidden = true
            }
            viewModel.closeBanner()
        }
    }
}

extension OrcaSwapV2.ConfirmSwapping {
    private final class WalletView: UIStackView {
        enum WalletType {
            case source, destination
        }
        
        // MARK: - Properties
        private let viewModel: OrcaSwapV2ConfirmSwappingViewModelType
        private let type: WalletType
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private lazy var coinLogoImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var amountLabel = UILabel(text: nil, textSize: 15, textAlignment: .center)
        private lazy var equityAmountLabel = UILabel(text: nil, textSize: 13, textColor: .textSecondary, textAlignment: .center)
        
        // MARK: - Initializers
        init(viewModel: OrcaSwapV2ConfirmSwappingViewModelType, type: WalletType) {
            self.viewModel = viewModel
            self.type = type
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 0, alignment: .center, distribution: .fill)
            layout()
            bind()
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Methods
        private func layout() {
            addArrangedSubviews {
                coinLogoImageView
                BEStackViewSpacing(12)
                amountLabel
                BEStackViewSpacing(3)
                equityAmountLabel
            }
        }
        
        private func bind() {
            let walletDriver = type == .source ? viewModel.sourceWalletDriver: viewModel.destinationWalletDriver
            
            walletDriver
                .drive(coinLogoImageView.rx.wallet)
                .disposed(by: disposeBag)
            
            let tokenAmountDriver = type == .source ? viewModel.inputAmountDriver: viewModel.estimatedAmountDriver
            
            Driver.combineLatest(
                walletDriver,
                tokenAmountDriver
            )
                .map {wallet, amount in
                    amount.toString(maximumFractionDigits: 9) + " " + wallet?.token.symbol
                }
                .drive(amountLabel.rx.text)
                .disposed(by: disposeBag)
            
            if type == .source {
                Driver.combineLatest(
                    walletDriver,
                    tokenAmountDriver
                )
                    .map {wallet, amount in
                        "~ " +
                            (amount * wallet?.priceInCurrentFiat).toString(maximumFractionDigits: 2) +
                            " " +
                            Defaults.fiat.code
                    }
                    .drive(equityAmountLabel.rx.text)
                    .disposed(by: disposeBag)
            } else if type == .destination {
                Driver.combineLatest(
                    walletDriver,
                    viewModel.minimumReceiveAmountDriver
                )
                    .map {wallet, amount in
                        "≥ " +
                        amount?.toString(maximumFractionDigits: 9) +
                        " " +
                        (wallet?.token.symbol ?? "")
                    }
                    .drive(equityAmountLabel.rx.text)
                    .disposed(by: disposeBag)
            }
        }
    }
}
