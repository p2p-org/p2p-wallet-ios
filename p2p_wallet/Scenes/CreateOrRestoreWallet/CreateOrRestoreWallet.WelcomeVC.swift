//
//  CreateOrRestoreWallet.WelcomeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import UIKit
import BEPureLayout

extension CreateOrRestoreWallet {
    class WelcomeVC: BEPagesVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .embeded
        }
        
        override func setUp() {
            super.setUp()
            view.backgroundColor = .clear
            viewControllers = [
                SlideVC {
                    create3dAppIconView()
                        .centeredHorizontallyView
                    UILabel(text: L10n.p2PWallet, textSize: 34, weight: .bold, textAlignment: .center)
                    UILabel(text: L10n.theFutureOfNonCustodialBankingTheEasyWayToBuySellAndHoldCryptos, textSize: 17, weight: .medium, numberOfLines: 0, textAlignment: .center)
                },
                SlideVC {
                    UIImageView(width: 196.94, height: 306, image: .p2pCamp)
                        .centeredHorizontallyView
                    BEStackViewSpacing(31.34)
                    UILabel(text: L10n.welcomeToP2PFamilyCamp, textSize: 34, weight: .bold, numberOfLines: 0, textAlignment: .center)
                }
            ]
            currentPageIndicatorTintColor = .h5887ff
            pageIndicatorTintColor = .d1d1d6
        }
        
        private func create3dAppIconView() -> UIView {
            let iconView = UIView(forAutoLayout: ())
            let backView = BERoundedCornerShadowView(shadowColor: .textBlack.withAlphaComponent(0.05), radius: 32, offset: .init(width: 0, height: 9), opacity: 1, cornerRadius: 12.5)
            backView.backgroundColor = .background
            backView.autoSetDimension(.width, toSize: 241.16)
            iconView.addSubview(backView)
            backView.autoPinEdge(toSuperviewEdge: .top, withInset: 24.53)
            backView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18.3)
            backView.autoAlignAxis(toSuperviewAxis: .vertical)
            
            let imageView = UIImageView(width: 375, height: 349.35, image: .walletsIcon3d)
            iconView.addSubview(imageView)
            imageView.autoPinEdge(toSuperviewEdge: .top)
            imageView.autoPinEdge(toSuperviewEdge: .bottom)
            imageView.autoAlignAxis(toSuperviewAxis: .vertical)
            
            return iconView
        }
    }
}

private class SlideVC: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .embeded
    }
    
    fileprivate let stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
    
    private let elements: [BEStackViewElement]
    init(@BEStackViewBuilder builder: () -> [BEStackViewElement]) {
        self.elements = builder()
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        
        // content stack view
        view.addSubview(stackView)
        stackView.autoPinEdge(toSuperviewSafeArea: .top)
        stackView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 20)
        stackView.autoPinEdge(toSuperviewSafeArea: .trailing, withInset: 20)
        stackView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 55)
        
        let spacer1 = UIView.spacer
        let spacer2 = UIView.spacer
        
        stackView.addArrangedSubview(spacer1)
        stackView.addArrangedSubviews(elements)
        stackView.addArrangedSubview(spacer2)
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor).isActive = true
    }
}
