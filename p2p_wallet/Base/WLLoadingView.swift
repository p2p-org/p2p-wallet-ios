//
//  WLLoadingView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/12/2020.
//

import Foundation

open class WLLoadingView: BEView {
    open override var tintColor: UIColor? {
        didSet { filledView.backgroundColor = tintColor }
    }
    
    lazy var filledView = UIView(forAutoLayout: ())
    
    var filledViewTrailingConstraint: NSLayoutConstraint!
    
    open override func commonInit() {
        super.commonInit()
        filledView.backgroundColor = backgroundColor
        addSubview(filledView)
        filledView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)
        filledViewTrailingConstraint = filledView.widthAnchor.constraint(equalTo: widthAnchor)
        
        filledViewTrailingConstraint.isActive = true
    }
    
    func setUp(state: FetcherState<Bool>) {
        filledView.layer.removeAllAnimations()
        switch state {
        case .loading:
            animate()
        case .initializing, .loaded, .error:
            filledViewTrailingConstraint.constant = 0
            layoutIfNeeded()
        }
    }
    
    private func animate() {
        filledViewTrailingConstraint.constant = -bounds.width
        layoutIfNeeded()
        UIView.animate(withDuration: TimeInterval(bounds.width / 100), delay: 0, options: .repeat) {
            self.filledViewTrailingConstraint.constant = 0
            self.layoutIfNeeded()
        }
    }
}
