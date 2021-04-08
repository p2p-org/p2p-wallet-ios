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
    var currentWallet: Wallet?
    
    private lazy var basicIconImageView = UIImageView(width: 24.38, height: 24.38, tintColor: .a3a5ba)
    private lazy var fromTokenImageView = CoinLogoImageView(width: 30, height: 30)
    private lazy var toTokenImageView = CoinLogoImageView(width: 30, height: 30)
    
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
    
    func setUp(transaction: SolanaSDK.AnyTransaction) {
        basicIconImageView.image = nil
        fromTokenImageView.alpha = 0
        toTokenImageView.alpha = 0
        switch transaction.value {
        case let transaction as SolanaSDK.CreateAccountTransaction:
            basicIconImageView.isHidden = false
            basicIconImageView.image = .transactionCreateAccount
        case let transaction as SolanaSDK.CloseAccountTransaction:
            basicIconImageView.isHidden = false
            basicIconImageView.image = .transactionCloseAccount
        case let transaction as SolanaSDK.TransferTransaction:
            // TODO: - Send, receive
            basicIconImageView.isHidden = false
            if currentWallet?.pubkey == transaction.source?.pubkey {
                basicIconImageView.image = .transactionSend
            }
            if currentWallet?.pubkey == transaction.destination?.pubkey {
                basicIconImageView.image = .transactionReceive
            }
            
        case let transaction as SolanaSDK.SwapTransaction:
            basicIconImageView.isHidden = true
            
            fromTokenImageView.alpha = 1
            toTokenImageView.alpha = 1
            
            fromTokenImageView.setUp(token: transaction.source)
            toTokenImageView.setUp(token: transaction.destination)
        default:
            basicIconImageView.isHidden = false
            basicIconImageView.image = .transactionSwap
        }
    }
}
