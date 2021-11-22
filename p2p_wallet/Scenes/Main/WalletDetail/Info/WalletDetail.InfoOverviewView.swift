//
//  WalletDetail.InfoOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import BEPureLayout
import UIKit

extension WalletDetail {
    class InfoOverviewView: WLOverviewView {
        // MARK: - Properties
        private let viewModel: WalletDetailViewModelType
        
        // MARK: - Subviews
        private lazy var coinImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var amountLabel = UILabel(text: "<amount>", textSize: 20, weight: .bold)
        private lazy var equityValueLabel = UILabel(text: "<equity value>", textSize: 13, weight: .semibold)
        private lazy var change24hLabel = UILabel(text: "<change 24h>", textSize: 13, weight: .semibold, textColor: .h5887ff)
        
        private lazy var sendButton = createButton(image: .buttonSend, title: L10n.send)
            .onTap(self, action: #selector(buttonSendDidTouch))
        private lazy var swapButton = createButton(image: .buttonSwap, title: L10n.swap)
            .onTap(self, action: #selector(buttonSwapDidTouch))
        
        // MARK: - Initializer
        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
            bind()
        }
        
        // MARK: - Methods
        override func createTopView() -> UIView {
            UIStackView(axis: .horizontal, spacing: 18, alignment: .center, distribution: .fill) {
                coinImageView
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                    equityValueLabel
                    change24hLabel
                }
            }
                .padding(.init(x: 18, y: 21))
        }
        
        override func createButtonsView() -> UIView {
            UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually) {
                sendButton
                swapButton
            }
        }
        
        func bind() {
            
        }
        
        // MARK: - Actions
        @objc private func buttonSendDidTouch() {
            
        }
        
        @objc private func buttonSwapDidTouch() {
            
        }
    }
}
