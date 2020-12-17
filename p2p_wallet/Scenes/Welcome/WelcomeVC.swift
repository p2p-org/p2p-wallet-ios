//
//  WelcomeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
class WelcomeVC: BEPagesVC, BEPagesVCDelegate {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    
    override func setUp() {
        super.setUp()
        viewControllers = [FirstVC(), SecondVC()]
        currentPageIndicatorTintColor = .textBlack
        pageIndicatorTintColor = .a4a4a4
        
        self.delegate = self
    }
    
    func bePagesVC(_ pagesVC: BEPagesVC, currentPageDidChangeTo currentPage: Int) {
        pageControl.isHidden = false
        if currentPage > 0 {
            pageControl.isHidden = true
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
}

extension WelcomeVC {
    class FirstVC: IntroVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.embeded}
        
        override func createIconView() -> UIView {
            UIStackView(axis: .horizontal, spacing: -100, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIImageView(width: 294, height: 183, image: .introBankCard1),
                UIImageView(width: 294, height: 183, image: .introBankCard1),
                UIImageView(width: 294, height: 183, image: .introBankCard1)
            ])
        }
    }
    
    class SecondVC: CreateOrRestoreWalletVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.embeded}
        
        override func createIconView() -> UIView {
            UIStackView(axis: .horizontal, spacing: -100, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIImageView(width: 294, height: 183, image: .introBankCard1),
                UIImageView(width: 294, height: 183, image: .introBankCard1),
                UIImageView(width: 294, height: 183, image: .introBankCard1)
            ])
        }
    }
}
