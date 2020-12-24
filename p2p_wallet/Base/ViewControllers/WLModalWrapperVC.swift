//
//  WLModalWrapperVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation

class WLModalWrapperVC: WLModalVC {
    override var padding: UIEdgeInsets {.init(x: 0, y: .defaultPadding)}
    var vc: UIViewController
    
    init(wrapped: UIViewController) {
        vc = wrapped
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(vc)
        // collectionView(didSelectItemAt) would not be called if
        // we add vc.view inside stackView or containerView, so I
        // add vc.view directly into `view`
        view.addSubview(vc.view)
        containerView.constraintToSuperviewWithAttribute(.bottom)?
            .isActive = false
        vc.view.autoPinEdge(.top, to: .bottom, of: containerView)
        vc.view.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        vc.didMove(toParent: self)
    }
    
}
