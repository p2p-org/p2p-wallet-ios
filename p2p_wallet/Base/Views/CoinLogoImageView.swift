//
//  CoinLogoImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation
import JazziconSwift

class CoinLogoImageView: BEView {
    // MARK: - Properties
    private let size: CGFloat
    static var cachedJazziconSeeds = [String: UInt64]()
    
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
    private var placeholderView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let placeholderView = placeholderView else {return}
            placeholderView.removeFromSuperview()
            insertSubview(placeholderView, at: 0)
            placeholderView.autoPinEdgesToSuperviewEdges()
            placeholderView.isHidden = true
        }
    }
    
    // MARK: - Initializer
    init(size: CGFloat, cornerRadius: CGFloat = 12) {
        self.size = size
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
        wrappingView.alpha = 0
        backgroundColor = .clear
        tokenIcon.isHidden = false
        placeholderView?.isHidden = true
        
        // with token
        if let image = token?.image {
            tokenIcon.image = image
        } else if let placeholderView = placeholderView {
            tokenIcon.isHidden = true
            placeholderView.isHidden = false
        } else {
            let jazzicon: Jazzicon
            if let token = token {
                let key = token.symbol.isEmpty ? token.address: token.symbol
                var seed = Self.cachedJazziconSeeds[key]
                if seed == nil {
                    seed = UInt64.random(in: 0..<10000000)
                    Self.cachedJazziconSeeds[key] = seed
                }
                
                jazzicon = Jazzicon(seed: seed!)
            } else {
                jazzicon = Jazzicon()
            }
            
            let jazziconImage = jazzicon.generateImage(size: size)
            if let urlString = token?.logoURI,
               let url = URL(string: urlString)
            {
                tokenIcon.kf.setImage(with: url, placeholder: jazziconImage)
            } else {
                tokenIcon.image = jazziconImage
            }
            
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
        self.placeholderView = placeholder
        return self
    }
}
