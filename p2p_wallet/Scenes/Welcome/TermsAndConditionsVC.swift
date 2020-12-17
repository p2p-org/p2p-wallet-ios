//
//  TermsAndConditionsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/12/2020.
//

import Foundation

class TermsAndConditionsVC: BaseVC {
    // MARK: - Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var containerView = UIView(backgroundColor: .vcBackground)
    
    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        let topGestureView = UIView(width: 71, height: 5, backgroundColor: .vcBackground, cornerRadius: 2.5)
        view.addSubview(topGestureView)
        topGestureView.autoPinEdge(toSuperviewSafeArea: .top)
        topGestureView.autoAlignAxis(toSuperviewAxis: .vertical)
        
        view.addSubview(containerView)
        containerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        containerView.autoPinEdge(.top, to: .bottom, of: topGestureView, withOffset: 8)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.roundCorners([.topLeft, .topRight], radius: 20)
    }
}
