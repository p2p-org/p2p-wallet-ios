//
//  SendToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

struct SendToken {
    enum NavigatableScene {
        case back
        case chooseTokenAndAmount(showAfterConfirmation: Bool)
        
        case chooseRecipientAndNetwork(showAfterConfirmation: Bool)
        case chooseNetwork
        
        case confirmation
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
    }
    
    struct Recipient: Hashable {
        init(address: String, name: String?, hasNoFunds: Bool, hasNoInfo: Bool = false) {
            self.address = address
            self.name = name
            self.hasNoFunds = hasNoFunds
            self.hasNoInfo = hasNoInfo
        }
        
        let address: String
        let name: String?
        let hasNoFunds: Bool
        let hasNoInfo: Bool
    }
    
    enum Network: String {
        case solana, bitcoin
        var icon: UIImage {
            switch self {
            case .solana:
                return .squircleSolanaIcon
            case .bitcoin:
                return .squircleBitcoinIcon
            }
        }
        var defaultFees: [Fee] {
            switch self {
            case .solana:
                return [.init(amount: 0, unit: Defaults.fiat.symbol)]
            case .bitcoin:
                return [.init(amount: 0.0002, unit: "renBTC"), .init(amount: 0.0002, unit: "SOL")]
            }
        }
    }
    
    struct Fee {
        var amount: Double
        let unit: String
    }
}

extension Array where Element == SendToken.Fee {
    func attributedString(
        prices: [String: Double],
        textSize: CGFloat = 15,
        tokenColor: UIColor = .textBlack,
        fiatColor: UIColor = .textSecondary,
        attributedSeparator: NSAttributedString = NSAttributedString(string: "\n")
    ) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString()
        
        for (index, fee) in self.enumerated() {
            let amountInUSD = fee.amount * prices[fee.unit]
            attributedText
                .text("\(fee.amount.toString(maximumFractionDigits: 9)) \(fee.unit)", size: textSize, color: tokenColor)
                .text(" (~\(Defaults.fiat.symbol)\(amountInUSD.toString(maximumFractionDigits: 2)))", size: textSize, color: fiatColor)
            if index < count - 1 {
                attributedText
                    .append(attributedSeparator)
            }
        }
        return attributedText
    }
}
