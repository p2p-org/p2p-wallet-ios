//
//  WLLoadingIndicatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/03/2021.
//

import Foundation

extension UIView {
    @discardableResult
    func showLoadingIndicatorView() -> WLLoadingIndicatorView {
        hideLoadingIndicatorView()
        let indicator = WLLoadingIndicatorView(forAutoLayout: ())
        addSubview(indicator)
        indicator.autoPinEdgesToSuperviewEdges()
        indicator.animate()
        return indicator
    }
    
    func hideLoadingIndicatorView() {
        subviews.first(where: {$0 is WLLoadingIndicatorView})?.removeFromSuperview()
    }
}

class WLLoadingIndicatorView: BEView {
    // MARK: - Subviews
    private lazy var spinner: BESpinnerView = {
        let spinner = BESpinnerView(width: 65, height: 65, cornerRadius: 65/2)
        spinner.endColor = .h5887ff
        return spinner
    }()
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        backgroundColor = UIColor.textWhite.withAlphaComponent(0.8)
        addSubview(spinner)
        spinner.autoCenterInSuperview()
        
        let imageView = UIImageView(width: 45, height: 45, cornerRadius: 45 / 2, image: .spinnerIcon)
        addSubview(imageView)
        imageView.autoCenterInSuperview()
    }
    
    func animate() {
        spinner.animate()
    }
}
