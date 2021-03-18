//
//  WLLoadingIndicatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/03/2021.
//

import Foundation

extension UIView {
    @discardableResult
    func showLoadingIndicatorView(presentationStyle: WLLoadingIndicatorView.PresentationType = .default, isBlocking: Bool = true, message: String? = nil) -> WLLoadingIndicatorView {
        hideLoadingIndicatorView()
        
        let indicator = WLLoadingIndicatorView(presentationType: presentationStyle, isBlocking: isBlocking)
        addSubview(indicator)
        indicator.autoPinEdgesToSuperviewEdges()
        indicator.message = message
        return indicator
    }
    
    func hideLoadingIndicatorView() {
        subviews.first(where: {$0 is WLLoadingIndicatorView})?.removeFromSuperview()
    }
}

class WLLoadingIndicatorView: BEView {
    // MARK: - Nested type
    enum PresentationType {
        case `default`, fullScreen
    }
    
    // MARK: - Properties
    private let presentationType: PresentationType
    private let isBlocking: Bool
    
    var message: String? {
        didSet { setUpTitleLabel() }
    }
    
    // MARK: - Subviews
    private lazy var stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .center, distribution: .fill, arrangedSubviews: [
        {
            let view = UIView(forAutoLayout: ())
            view.addSubview(spinner)
            spinner.autoPinEdgesToSuperviewEdges()
            let imageView = UIImageView(width: presentationType == .fullScreen ? 45: 29, height: presentationType == .fullScreen ? 45: 29, cornerRadius: (presentationType == .fullScreen ? 45: 29) / 2, image: .spinnerIcon)
            view.addSubview(imageView)
            imageView.autoCenterInSuperview()
            return view
        }(),
        titleLabel
    ])
    
    private lazy var spinner: BESpinnerView = {
        let spinner = BESpinnerView(width: presentationType == .fullScreen ? 65: 47, height: presentationType == .fullScreen ? 65: 47, cornerRadius: (presentationType == .fullScreen ? 65: 47)/2)
        spinner.endColor = .h5887ff
        spinner.lineWidth = presentationType == .fullScreen ? 4: 3
        return spinner
    }()
    
    private lazy var titleLabel = UILabel(weight: .semibold, textColor: .textWhite)
    
    // MARK: - Initializer
    init(presentationType: PresentationType, isBlocking: Bool) {
        self.presentationType = presentationType
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
        
        if presentationType == .fullScreen {
            backgroundColor = UIColor.white.withAlphaComponent(0.8)
            
            addSubview(stackView)
            stackView.autoCenterInSuperview()
        } else {
            backgroundColor = .clear
            
            addSubview(stackView.padding(.init(all: 13), backgroundColor: UIColor.textBlack.withAlphaComponent(0.65), cornerRadius: 12))
            stackView.wrapper?.autoCenterInSuperview()
        }
        
        setUpTitleLabel()
    }
    
    func animate() {
        spinner.animate()
    }
    
    // MARK: - Helpers
    private func setUpTitleLabel() {
        titleLabel.text = message
        if message != nil, !message!.hasSuffix("...") {
            titleLabel.text = message! + "..."
        }
        titleLabel.isHidden = message == nil
    }
}
