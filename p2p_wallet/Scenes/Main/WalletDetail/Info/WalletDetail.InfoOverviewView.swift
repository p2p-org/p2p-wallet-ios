//
//  WalletDetail.InfoOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import BEPureLayout
import UIKit
import RxSwift

extension WalletDetail {
    class InfoOverviewView: WLOverviewView {
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private let viewModel: WalletDetailViewModelType
        
        // MARK: - Subviews
        private lazy var coinImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var amountLabel = UILabel(text: "<amount>", textSize: 20, weight: .bold)
        private lazy var equityValueLabel = UILabel(text: "<equity value>", textSize: 13, weight: .semibold)
        private lazy var change24hLabel = UILabel(text: "<change 24h>", textSize: 13, weight: .semibold, textColor: .h5887ff)
        
        private lazy var buyButton = createButton(image: .buttonBuy, title: L10n.buy.uppercaseFirst)
            .onTap(self, action: #selector(buttonBuyDidTouch))
        private lazy var sendButton = createButton(image: .buttonSend, title: L10n.send)
            .onTap(self, action: #selector(buttonSendDidTouch))
        private lazy var swapButton = createButton(image: .buttonSwap, title: L10n.swap)
            .onTap(self, action: #selector(buttonSwapDidTouch))
        
        // MARK: - Initializer
        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
            bind()
            change24hLabel.isHidden = true // TODO: - Remove later
        }
        
        // MARK: - Methods
        override func createTopView() -> UIView {
            UIStackView(axis: .horizontal, spacing: 18, alignment: .center, distribution: .fill) {
                coinImageView
                
                UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                    amountLabel
                    UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                        equityValueLabel
                        change24hLabel
                    }
                }
            }
                .padding(.init(x: 18, y: 21))
        }
        
        override func createButtonsView() -> UIView {
            let stackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually)
            var arrangedSubviews = [sendButton, swapButton]
            if viewModel.canBuyToken {
                arrangedSubviews.insert(buyButton, at: 0)
            }
            stackView.addArrangedSubviews(arrangedSubviews)
            return stackView
        }
        
        func bind() {
            // logo
            viewModel.walletDriver
                .drive(onNext: {[weak self] wallet in
                    self?.coinImageView.setUp(wallet: wallet)
                })
                .disposed(by: disposeBag)
            
            // amountLabel
            viewModel.walletDriver.map {
                "\($0?.amount.toString(maximumFractionDigits: 9) ?? "") \($0?.token.symbol ?? "")"
            }
                .drive(amountLabel.rx.text)
                .disposed(by: disposeBag)
            
            // equityValue label
            viewModel.walletDriver.map {
                $0?.amountInCurrentFiat
                    .toString(maximumFractionDigits: 2)
            }
                .map {Defaults.fiat.symbol + " " + ($0 ?? "0")}
                .drive(equityValueLabel.rx.text)
                .disposed(by: disposeBag)
            
            // changeLabel
            viewModel.walletDriver.map {
                "\($0?.price?.change24h?.percentage?.toString(maximumFractionDigits: 2, showPlus: true) ?? "")% \(L10n._24Hours)"
            }
                .drive(change24hLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.walletDriver.map {
                $0?.price?.change24h?.percentage >= 0 ? UIColor.attentionGreen: UIColor.alert
            }
                .drive(change24hLabel.rx.textColor)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func buttonSendDidTouch() {
            viewModel.sendTokens()
        }
        
        @objc private func buttonSwapDidTouch() {
            viewModel.swapTokens()
        }
        
        @objc private func buttonBuyDidTouch() {
            viewModel.buyTokens()
        }
    }
}
