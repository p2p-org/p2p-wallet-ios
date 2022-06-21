//
//  CoinLogoImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation
import JazziconSwift
import RxSwift
import UIKit

class CoinLogoImageView: BEView {
    static var cachedJazziconSeeds = [String: UInt32]()

    // MARK: - Properties

    private let size: CGFloat

    private var seed: UInt32? {
        willSet {
            setNeedsDisplay()
        }
    }

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

    // MARK: - Initializer

    init(size: CGFloat, cornerRadius: CGFloat = 12, backgroundColor: UIColor? = nil) {
        self.size = size
        super.init(frame: .zero)
        configureForAutoLayout()
        autoSetDimensions(to: .init(width: size, height: size))

        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true

        self.backgroundColor = backgroundColor ?? .gray
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let seed = seed, let context = UIGraphicsGetCurrentContext() else {
            return
        }

        let jazzicon = Jazzicon(seed: seed)
        jazzicon.draw(with: context, in: rect)
    }

    override func commonInit() {
        super.commonInit()

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

    func setUp(token: SolanaSDK.Token? = nil, placeholder: UIImage? = nil) {
        // default
        wrappingView.alpha = 0
        backgroundColor = .clear
        tokenIcon.isHidden = false
        seed = nil

        // with token
        if let token = token {
            if let image = token.image {
                tokenIcon.image = image
            } else {
                let key = token.symbol.isEmpty ? token.address : token.symbol
                var seed = Self.cachedJazziconSeeds[key]
                if seed == nil {
                    seed = UInt32.random(in: 0 ..< 10_000_000)
                    Self.cachedJazziconSeeds[key] = seed
                }

                tokenIcon.isHidden = true
                self.seed = seed

                tokenIcon.setImage(urlString: token.logoURI) { [weak self] result in
                    switch result {
                    case .success:
                        self?.tokenIcon.isHidden = false
                        self?.seed = nil
                    case .failure:
                        self?.tokenIcon.isHidden = true
                    }
                }
            }
        } else {
            tokenIcon.image = placeholder
        }

        // wrapped by
        if let wrappedBy = token?.wrappedBy {
            wrappingView.alpha = 1
            wrappingTokenIcon.image = wrappedBy.image
        }
    }
}

extension Reactive where Base: CoinLogoImageView {
    var wallet: Binder<Wallet?> {
        Binder(base) { view, wallet in
            view.setUp(wallet: wallet)
        }
    }
}
