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
        // MARK: - Subviews
        private lazy var coinImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        private lazy var amountLabel = UILabel(text: "<amount>", textSize: 20, weight: .bold)
        private lazy var equityValueLabel = UILabel(text: "<equity value>", textSize: 13, weight: .semibold)
        private lazy var change24hLabel = UILabel(text: "<change 24h>", textSize: 13, weight: .semibold)
        
        private lazy var sendButton = createButton(image: .buttonSend, title: L10n.send)
            .onTap(self, action: #selector(buttonSendDidTouch))
        private lazy var swapButton = createButton(image: .buttonSwap, title: L10n.swap)
            .onTap(self, action: #selector(buttonSwapDidTouch))
        
        // MARK: - Actions
        @objc private func buttonSendDidTouch() {
            
        }
        
        @objc private func buttonSwapDidTouch() {
            
        }
    }
}

private func createButton(image: UIImage, title: String) -> UIView {
    let view = UIView(forAutoLayout: ())
    
    let stackView = UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill)
        {
            UIImageView(width: 24, height: 24, image: image, tintColor: .h5887ff)
            UILabel(text: title, textSize: 15, weight: .medium, textColor: .h5887ff)
        }
    
    view.addSubview(stackView)
    stackView.autoAlignAxis(toSuperviewAxis: .vertical)
    stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
    return view
}
