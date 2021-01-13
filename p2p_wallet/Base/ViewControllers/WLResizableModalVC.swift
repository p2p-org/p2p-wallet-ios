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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewDidSwipe(_:)))
        view.addGestureRecognizer(panGesture)
        view.isUserInteractionEnabled = true
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        ResizablePresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    var originalTop: CGFloat?
    @objc func viewDidSwipe(_ gestureRecognizer: UIPanGestureRecognizer) {
        let presentationController = self.presentationController as! ResizablePresentationController
        presentationController.presentedViewDidSwipe(gestureRecognizer, originalTop: &originalTop)
    }
}
