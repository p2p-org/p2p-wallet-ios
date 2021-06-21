//
//  WLLoadingIndicatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/03/2021.
//

import Foundation

extension UIView {
    @discardableResult
    func showLoadingIndicatorView(isBlocking: Bool = true) -> WLLoadingIndicatorView {
        hideLoadingIndicatorView()
        
        let indicator = WLLoadingIndicatorView(isBlocking: isBlocking)
        addSubview(indicator)
        indicator.autoPinEdgesToSuperviewEdges()
        return indicator
    }
    
    func hideLoadingIndicatorView() {
        subviews.first(where: {$0 is WLLoadingIndicatorView})?.removeFromSuperview()
    }
}

class WLLoadingIndicatorView: BEView {
    // MARK: - Properties
    private let isBlocking: Bool
    
    // MARK: - Subviews
    private lazy var contentView: UIView = {
        let view = UIView(forAutoLayout: ())
        view.addSubview(spinner)
        spinner.autoPinEdgesToSuperviewEdges()
        let imageView = UIImageView(width: 45, height: 45, cornerRadius: 45/2, image: .spinnerIcon)
        view.addSubview(imageView)
        imageView.autoCenterInSuperview()
        return view
    }()
    
    private lazy var spinner: BESpinnerView = {
        let spinner = BESpinnerView(width: 65, height: 65, cornerRadius: 65/2)
        spinner.endColor = .h5887ff
        spinner.lineWidth = 4
        return spinner
    }()
    
    // MARK: - Initializer
    init(isBlocking: Bool) {
        self.isBlocking = isBlocking
        super.init(frame: .zero)
        self.configureForAutoLayout()
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        animate()
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        isUserInteractionEnabled = isBlocking
        
        addSubview(contentView)
        contentView.autoCenterInSuperview()
    }
    
    func animate() {
        spinner.animate()
    }
}
