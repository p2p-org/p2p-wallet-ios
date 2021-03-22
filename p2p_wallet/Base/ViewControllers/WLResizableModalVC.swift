//
//  WLResizableModalVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

class WLResizableModalVC: WLModalVC, UIViewControllerTransitioningDelegate {
    override init() {
        super.init()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        ExpandablePresentationController(presentedViewController: presented, presenting: presenting)
    }
}
