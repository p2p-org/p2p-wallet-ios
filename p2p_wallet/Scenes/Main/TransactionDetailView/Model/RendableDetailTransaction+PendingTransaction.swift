//
//  RendableDetailTransaction+PendingTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Combine
import Foundation
import SolanaPricesAPIs

struct RendableDetailPendingTransaction: RendableDetailTransaction {
    let trx: PendingTransaction
    
    let priceService: PricesService
    
    var status: DetailTransactionStatus {
        if trx.transactionId != nil {
            return .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted)
        }
        
        switch trx.status {
        case .error:
            return .error(message: NSAttributedString(string: L10n.theTransactionWasRejectedByTheSolanaBlockchain))
        case .finalized:
            return .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted)
        default:
            return .loading(message: L10n.itUsuallyTakes520SecondsForATransactionToComplete)
        }
    }
    
    var title: String {
        if trx.transactionId != nil {
            return L10n.transactionSucceeded
        }
        
        switch trx.status {
        case .error:
            return L10n.transactionFailed
        case .finalized:
            return L10n.transactionSucceeded
        default:
            return L10n.transactionSubmitted
        }
    }
    
    var subtitle: String {
        trx.sentAt.string(withFormat: "MMMM dd, yyyy @ HH:mm", locale: Locale.base)
    }
    
    var signature: String? {
        trx.transactionId
    }
    
    var icon: DetailTransactionIcon {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            if
                let urlStr = transaction.walletToken.token.logoURI,
                let url = URL(string: urlStr)
            {
                return .single(url)
            } else {
                return .icon(.transactionSend)
            }
            
        case let transaction as SwapTransaction:
            let fromUrlStr = transaction.sourceWallet.token.logoURI
            let toUrlStr = transaction.destinationWallet.token.logoURI
            
            guard let fromUrlStr, let toUrlStr else {
                return .icon(.buttonSwap)
            }
            
            let fromUrl = URL(string: fromUrlStr)
            let toUrl = URL(string: toUrlStr)
            
            guard let fromUrl, let toUrl else {
                return .icon(.buttonSwap)
            }
            
            return .double(fromUrl, toUrl)
        case let transaction as JupiterSwapTransaction:
            let fromUrlStr = transaction.fromToken.jupiterToken.logoURI
            let toUrlStr = transaction.toToken.jupiterToken.logoURI

            guard let fromUrlStr, let toUrlStr else {
                return .icon(.buttonSwap)
            }

            let fromUrl = URL(string: fromUrlStr)
            let toUrl = URL(string: toUrlStr)

            guard let fromUrl, let toUrl else {
                return .icon(.buttonSwap)
            }

            return .double(fromUrl, toUrl)

        default:
            return .icon(.transactionUndefined)
            // return .icon(.planet)
        }
    }
    
    var amountInFiat: DetailTransactionChange {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            return .negative("-\(transaction.amountInFiat.fiatAmountFormattedString())")
        case let transaction as SwapTransaction:
            let amountInFiat: Double = (transaction.amount * priceService.currentPrice(mint: transaction.sourceWallet.token.address)?.value)
            return .unchanged("\(amountInFiat.fiatAmountFormattedString())")
        case let transaction as JupiterSwapTransaction:
            return .unchanged(transaction.amountFiat.fiatAmountFormattedString())
        default:
            return .unchanged("")
        }
    }
    
    var amountInToken: String {
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            return "\(transaction.amount.tokenAmountFormattedString(symbol: transaction.walletToken.token.symbol))"
        case let transaction as SwapTransaction:
            return "\(transaction.amount.tokenAmountFormattedString(symbol: transaction.sourceWallet.token.symbol)) → \(transaction.estimatedAmount.tokenAmountFormattedString(symbol: transaction.destinationWallet.token.symbol))"
        case let transaction as JupiterSwapTransaction:
            return transaction.mainDescription
        default:
            return ""
        }
    }
    
    var extra: [DetailTransactionExtraInfo] {
        var result: [DetailTransactionExtraInfo] = []
        
        switch trx.rawTransaction {
        case let transaction as SendTransaction:
            switch transaction.recipient.category {
            case let .username(name, domain):
                result.append(
                    .init(
                        title: L10n.sendTo,
                        value: RecipientFormatter.username(name: name, domain: domain),
                        copyableValue: "\(name).\(domain)"
                    )
                )
            case let .solanaTokenAddress(walletAddress, _):
                result.append(
                    .init(
                        title: L10n.sendTo,
                        value: RecipientFormatter.format(destination: walletAddress.base58EncodedString),
                        copyableValue: walletAddress.base58EncodedString
                    )
                )
            case .solanaAddress:
                result.append(
                    .init(
                        title: L10n.sendTo,
                        value: RecipientFormatter.format(destination: transaction.recipient.address),
                        copyableValue: transaction.recipient.address
                    )
                )
            default:
                break
            }
            
            if transaction.feeInToken.total == 0 {
                result.append(.init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp))
            } else {
                let feeAmount: Double = transaction.feeInToken.total.convertToBalance(decimals: transaction.payingFeeWallet?.token.decimals)
                let formatedFeeAmount: String = feeAmount.tokenAmountFormattedString(symbol: transaction.payingFeeWallet?.token.symbol ?? "")
                result.append(.init(title: L10n.transactionFee, value: formatedFeeAmount))
            }
        case let transaction as SwapTransaction:
            if let networkFees = transaction.networkFees {
                if networkFees.total == 0 {
                    result.append(.init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp))
                } else {
                    let feeAmount: Double = networkFees.total.convertToBalance(decimals: networkFees.token.decimals)
                    let formatedFeeAmount: String = feeAmount.tokenAmountFormattedString(symbol: networkFees.token.symbol)
                    
                    let feeAmountInFiat: Double = feeAmount * priceService.currentPrice(mint: networkFees.token.address)?.value
                    let formattedFeeAmountInFiat: String = feeAmountInFiat.fiatAmountFormattedString()
                    
                    result.append(.init(title: L10n.transactionFee, value: "\(formatedFeeAmount) (\(formattedFeeAmountInFiat))"))
                }
            }

        case let transaction as JupiterSwapTransaction:
            result.append(.init(title: L10n.transactionFee, value: L10n.freePaidByKeyApp))

        default:
            break
        }
        
        return result
    }
    
    var actions: [DetailTransactionAction] {
        switch trx.status {
        case .finalized:
            return [.share, .explorer]
        default:
            return []
        }
    }
}
    
