//
//  WelcomeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
class WelcomeVC: BEPagesVC, BEPagesVCDelegate {
    override func setUp() {
        super.setUp()
        viewControllers = [IntroVC(), CreateWalletVC()]
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
}
