//
//  TransactionImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation

class TransactionImageView: BEView {
    private let _backgroundColor: UIColor?
    private let _cornerRadius: CGFloat?

    private lazy var basicIconImageView = UIImageView(width: 24.38, height: 24.38, tintColor: .iconSecondary)
    private lazy var fromTokenImageView = CoinLogoImageView(size: 30)
    private lazy var toTokenImageView = CoinLogoImageView(size: 30)

    init(size: CGFloat, backgroundColor: UIColor? = nil, cornerRadius: CGFloat? = nil) {
        _backgroundColor = backgroundColor
        _cornerRadius = cornerRadius
        super.init(frame: .zero)
        configureForAutoLayout()
        autoSetDimensions(to: .init(width: size, height: size))
    }

    override func commonInit() {
        super.commonInit()
        let backgroundView = UIView(backgroundColor: _backgroundColor, cornerRadius: _cornerRadius)
        addSubview(backgroundView)
        backgroundView.autoPinEdgesToSuperviewEdges()

        addSubview(basicIconImageView)
        basicIconImageView.autoCenterInSuperview()

        addSubview(fromTokenImageView)
        fromTokenImageView.autoPinToTopLeftCornerOfSuperview()

        addSubview(toTokenImageView)
        toTokenImageView.autoPinToBottomRightCornerOfSuperview()

        fromTokenImageView.alpha = 0
        toTokenImageView.alpha = 0
    }

    func setUp(transaction: SolanaSDK.ParsedTransaction) {
        fromTokenImageView.alpha = 0
        toTokenImageView.alpha = 0

        basicIconImageView.isHidden = false
        basicIconImageView.image = transaction.icon

        switch transaction.value {
        case let transaction as SolanaSDK.SwapTransaction:
            basicIconImageView.isHidden = true

            fromTokenImageView.alpha = 1
            toTokenImageView.alpha = 1

            fromTokenImageView.setUp(token: transaction.source?.token)
            toTokenImageView.setUp(token: transaction.destination?.token)
        default:
            break
        }
    }
}
