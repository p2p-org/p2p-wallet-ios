//
//  SendToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import RxSwift
import RxCocoa
import SolanaSwift

enum SendToken {
    enum NavigatableScene {
        case back
        case chooseTokenAndAmount(showAfterConfirmation: Bool)
        
        case chooseRecipientAndNetwork(showAfterConfirmation: Bool, preSelectedNetwork: Network?)
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
    }
    
    enum PayingWalletStatus: Equatable {
        case loading
        case invalid
        case valid(amount: SolanaSDK.Lamports, enoughBalance: Bool)
        
        var isValidAndEnoughBalance: Bool {
            switch self {
            case .valid(_, let enoughBalance):
                return enoughBalance
            default:
                return false
            }
        }
        
        var feeAmount: SolanaSDK.Lamports? {
            switch self {
            case .valid(let amount, _):
                return amount
            default:
                return nil
            }
        }
    }
}

extension SolanaSDK.FeeAmount {
    func attributedString(
        prices: [String: Double],
        textSize: CGFloat = 15,
        tokenColor: UIColor = .textBlack,
        fiatColor: UIColor = .textSecondary,
        attributedSeparator: NSAttributedString = NSAttributedString(string: "\n")
    ) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString()
        
        // if empty
        if total == 0 && (others == nil || others?.isEmpty == true) {
            attributedText
                .text("\(Defaults.fiat.symbol)0", size: 13, weight: .semibold, color: .attentionGreen)
            return attributedText
        }
        
        // total (in SOL)
        let totalFeeInSOL = total.convertToBalance(decimals: 9)
        let totalFeeInUSD = totalFeeInSOL * prices["SOL"]
        attributedText
            .text("\(totalFeeInSOL.toString(maximumFractionDigits: 9)) SOL", size: textSize, color: tokenColor)
            .text(" (~\(Defaults.fiat.symbol)\(totalFeeInUSD.toString(maximumFractionDigits: 2)))", size: textSize, color: fiatColor)
        
        // other fees
        if let others = others {
            attributedText.append(attributedSeparator)
            for (index, fee) in others.enumerated() {
                let amountInUSD = fee.amount * prices[fee.unit]
                attributedText
                    .text("\(fee.amount.toString(maximumFractionDigits: 9)) \(fee.unit)", size: textSize, color: tokenColor)
                    .text(" (~\(Defaults.fiat.symbol)\(amountInUSD.toString(maximumFractionDigits: 2)))", size: textSize, color: fiatColor)
                if index < others.count - 1 {
                    attributedText
                        .append(attributedSeparator)
                }
            }
        }
        return attributedText
    }
    
    func attributedStringForTransactionFee(solPrice: Double?) -> NSMutableAttributedString {
        if transaction == 0 {
            return NSMutableAttributedString()
                .text(L10n.free + " ", size: 15, weight: .semibold)
                .text("(\(L10n.PaidByP2p.org))", size: 15, color: .h34c759)
        } else {
            let fee = transaction.convertToBalance(decimals: 9)
            return feeAttributedString(fee: fee, unit: "SOL", price: solPrice)
        }
    }
    
    func attributedStringForAccountCreationFee(solPrice: Double?) -> NSMutableAttributedString? {
        guard accountBalances > 0 else {return nil}
        let fee = accountBalances.convertToBalance(decimals: 9)
        return feeAttributedString(fee: fee, unit: "SOL", price: solPrice)
    }
    
    func attributedStringForTotalFee(solPrice: Double?) -> NSMutableAttributedString {
        let fee = total.convertToBalance(decimals: 9)
        return feeAttributedString(fee: fee, unit: "SOL", price: solPrice)
    }
    
    func attributedStringForOtherFees(
        prices: [String: Double],
        attributedSeparator: NSAttributedString = NSAttributedString(string: "\n")
    ) -> NSMutableAttributedString? {
        guard let others = others, !others.isEmpty else {return nil}
        let attributedText = NSMutableAttributedString()
        for (index, fee) in others.enumerated() {
            attributedText
                .append(feeAttributedString(fee: fee.amount, unit: fee.unit, price: prices[fee.unit]))
            if index < others.count - 1 {
                attributedText
                    .append(attributedSeparator)
            }
        }
        return attributedText
    }
}

private func feeAttributedString(fee: Double, unit: String, price: Double?) -> NSMutableAttributedString {
    let feeInFiat = fee * price
    return NSMutableAttributedString()
        .text("\(fee.toString(maximumFractionDigits: 9)) \(unit)", size: 15, color: .textBlack)
        .text(" (~\(Defaults.fiat.symbol)\(feeInFiat.toString(maximumFractionDigits: 2)))", size: 15, color: .textSecondary)
}
