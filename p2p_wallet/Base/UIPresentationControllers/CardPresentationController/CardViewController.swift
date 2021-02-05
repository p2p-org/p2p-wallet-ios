//
//  CardViewController.swift
//  Commun
//
//  Created by Chung Tran on 12/13/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation

class CardViewController: BaseVStackVC {
    var contentView: UIView
    
    init(contentView: UIView) {
        self.contentView = contentView
        super.init()
        
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    
    override func setUp() {
        super.setUp()
       
        contentView.configureForAutoLayout()
        
        view.addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges()
    }
}

extension CardViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CardPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
