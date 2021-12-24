//
//  WLModalViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2021.
//

import Foundation

class WLModalViewController: BaseVC, CustomPresentableViewController {
    var transitionManager: UIViewControllerTransitioningDelegate?
    
    private var child: UIView!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.roundCorners([.topLeft, .topRight], radius: 18)
    }
    
    override func setUp() {
        super.setUp()
        
        // indicator
        let indicator = UIView(width: 31, height: 4, backgroundColor: .d1d1d6, cornerRadius: 2)
        view.addSubview(indicator)
        indicator.autoPinEdge(toSuperviewEdge: .top, withInset: 6)
        indicator.autoAlignAxis(toSuperviewAxis: .vertical)
        
        // child
        child = build()
        view.addSubview(child)
        child.autoPinEdge(.top, to: .bottom, of: indicator, withOffset: 6)
        child.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        
        layout()
    }
    
    func layout() {}
    
    func build() -> UIView {
        fatalError("build method is not implemented")
    }
    
    func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        6 + 4 + 6 + child.fittingHeight(targetWidth: targetWidth)
    }
}
