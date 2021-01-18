//
//  WelcomeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import SwiftUI

class WelcomeVC: BEPagesVC, BEPagesVCDelegate {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func setUp() {
        super.setUp()
        viewControllers = [FirstVC(), SecondVC()]
        currentPageIndicatorTintColor = .white
        pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        
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
    class FirstVC: CreateOrRestoreWalletVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .embeded
        }
        
        override func setUp() {
            super.setUp()
            titleLabel.text = L10n.p2PWallet
            descriptionLabel.text = L10n.secureNonCustodialBankOfFuture + "\n" + L10n.simpleFinanceForEveryone
            buttonsStackView.alpha = 0
        }
    }
    
    class SecondVC: CreateOrRestoreWalletVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .embeded
        }
        
        override func setUp() {
            super.setUp()
            titleLabel.text = L10n.p2PWallet
            descriptionLabel.text = L10n.secureNonCustodialBankOfFuture + "\n" + L10n.simpleFinanceForEveryone
        }
    }
}

@available(iOS 13, *)
struct WelcomeVC_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                WelcomeVC()
            }
            .previewDevice("iPhone SE (2nd generation)")
        }
    }
}
