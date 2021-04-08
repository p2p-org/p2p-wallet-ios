//
//  TransactionImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation

class TransactionImageView: BEView {
    private lazy var basicIconImageView = UIImageView(width: 24.38, height: 24.38, tintColor: .a3a5ba)
    
    override func commonInit() {
        super.commonInit()
        addSubview(basicIconImageView)
        basicIconImageView.autoCenterInSuperview()
    }
    
    func setUp(transaction: SolanaSDK.AnyTransaction) {
        basicIconImageView.image = nil
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
            
        case let transaction as SolanaSDK.SwapTransaction:
            basicIconImageView.isHidden = true
            basicIconImageView.image = .transactionSwap
        default:
            basicIconImageView.isHidden = false
            basicIconImageView.image = .transactionSwap
        }
    }
}
