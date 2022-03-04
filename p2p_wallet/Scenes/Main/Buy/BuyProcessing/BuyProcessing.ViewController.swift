//
//  BuyProcessing.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/09/2021.
//

import Foundation
import UIKit

extension BuyProcessing {
    class ViewController: WLIndicatorModalVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .hidden }
        
        // MARK: - Properties
        private let widgetVC: BuyTokenWidgetViewController
        private lazy var headerView = UIStackView(axis: .horizontal, spacing: 14, alignment: .center, distribution: .fill, arrangedSubviews: [
            UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
            UILabel(text: L10n.buy, textSize: 17, weight: .semibold)
        ])
            .padding(.init(all: 20))
        
        // MARK: - Methods
        init(provider: Buy.ProcessingService) {
            widgetVC = .init(provider: provider, loadingView: WLSpinnerView(size: 65, endColor: .h5887ff))
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            
            let rootView = UIView(forAutoLayout: ())
            let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
                headerView
                UIView.defaultSeparator()
                rootView
            }
            
            containerView.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges()
            
            add(child: widgetVC, to: rootView)
        }
    }
}

enum BuyProviderType: Equatable {
    case transak
    case moonpay
    
    static var `default`: Self {
        .moonpay
    }
    
    func isSupported(symbol: String) -> Bool {
        switch self {
        case .moonpay:
            return symbol == "ETH"
        case .transak:
            return symbol == "SOL" || symbol == "USDT"
        }
    }
}
