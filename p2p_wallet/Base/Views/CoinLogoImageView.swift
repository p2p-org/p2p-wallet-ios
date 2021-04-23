//
//  CoinLogoImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

class CoinLogoImageView: BEView {
    // MARK: - Subviews
    lazy var tokenIcon = UIImageView(tintColor: .textBlack)
    lazy var wrappingTokenIcon = UIImageView(width: 16, height: 16, cornerRadius: 4)
        .border(width: 1, color: .h464646)
    lazy var wrappingView: BERoundedCornerShadowView = {
        let view = BERoundedCornerShadowView(
            shadowColor: UIColor.textWhite.withAlphaComponent(0.25),
            radius: 2,
            offset: CGSize(width: 0, height: 2),
            opacity: 1,
            cornerRadius: 4
        )
        
        view.addSubview(wrappingTokenIcon)
        wrappingTokenIcon.autoPinEdgesToSuperviewEdges()
        
        return view
    }()
    private var placeholder: UIView?
    
    // MARK: - Initializer
    init(size: CGFloat, cornerRadius: CGFloat = 12) {
        super.init(frame: .zero)
        configureForAutoLayout()
        autoSetDimensions(to: .init(width: size, height: size))
        
        tokenIcon.layer.cornerRadius = cornerRadius
        tokenIcon.layer.masksToBounds = true
    }
    
    override func commonInit() {
        super.commonInit()
        backgroundColor = .gray
        
        addSubview(tokenIcon)
        tokenIcon.autoPinEdgesToSuperviewEdges()
        
        addSubview(wrappingView)
        wrappingView.autoPinEdge(toSuperviewEdge: .trailing)
        wrappingView.autoPinEdge(toSuperviewEdge: .bottom)
        wrappingView.alpha = 0 // UNKNOWN: isHidden not working
    }
    
    func setUp(wallet: Wallet? = nil) {
        setUp(token: wallet?.token)
    }
    
    func setUp(token: SolanaSDK.Token? = nil) {
        // default
        placeholder?.isHidden = true
        tokenIcon.isHidden = false
        wrappingView.alpha = 0
        backgroundColor = .clear
        
        // with token
        if let token = token {
            tokenIcon.image = token.image
        } else if let placeholder = placeholder {
            placeholder.isHidden = false
            tokenIcon.isHidden = true
        }
        
        // wrapped by
        if let wrappedBy = token?.wrappedBy {
            wrappingView.alpha = 1
            wrappingTokenIcon.image = wrappedBy.image
        }
    }
    
    func with(wallet: Wallet) -> Self {
        setUp(wallet: wallet)
        return self
    }
    
    func with(token: SolanaSDK.Token?) -> Self {
        setUp(token: token)
        return self
    }
    
    func with(placeholder: UIView) -> Self {
        self.placeholder?.removeFromSuperview()
        self.placeholder = placeholder
        insertSubview(placeholder, at: 0)
        placeholder.autoPinEdgesToSuperviewEdges()
        setUp(wallet: nil)
        return self
    }
}
