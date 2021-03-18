//
//  WLLoadingIndicatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/03/2021.
//

import Foundation

class WLLoadingIndicatorView: BEView {
    // MARK: - Subviews
    private lazy var spinner: BESpinnerView = {
        let spinner = BESpinnerView(forAutoLayout: ())
        spinner.endColor = .h5887ff
        return spinner
    }()
    
    // MARK: - Methods
    init() {
        super.init(frame: .zero)
        configureForAutoLayout()
        autoSetDimensions(to: CGSize(width: 65, height: 65))
    }
    
    override func commonInit() {
        super.commonInit()
        addSubview(spinner)
        spinner.autoPinEdgesToSuperviewEdges()
        
        let imageView = UIImageView(width: 45, height: 45, cornerRadius: 45 / 2, image: .spinnerIcon)
        addSubview(imageView)
        imageView.autoCenterInSuperview()
    }
    
    func animate() {
        spinner.animate()
    }
}
