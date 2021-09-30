//
//  SwapToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

struct SwapToken {
    enum NavigatableScene {
        case chooseSourceWallet
        case chooseDestinationWallet
        case settings
        case chooseSlippage
        case swapFees
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
    }
    
    struct Fee {
        enum FeeType {
            case liquidityProviderFee
            case networkFee
            case accountCreationFee
            case orderCreationFee
            case transactionFee
        }
        
        let type: FeeType
        let lamports: SolanaSDK.Lamports
        let token: SolanaSDK.Token
        var toString: (() -> String?)?
    }
}

protocol SwapTokenScenesFactory {
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool, handler: WalletDidSelectHandler) -> ChooseWallet.ViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
}

protocol SwapTokenApiClient {
    func getLamportsPerSignature() -> Single<SolanaSDK.Lamports>
    func getCreatingTokenAccountFee() -> Single<UInt64>
}

extension SolanaSDK: SwapTokenApiClient {}

extension Array where Element == SwapToken.Fee {
    var networkFee: SwapToken.Fee {
        if let networkFee = first(where: {$0.type == .networkFee}) {
            return networkFee
        }
        
        let networkFeeTypes: [SwapToken.Fee.FeeType] = [.accountCreationFee, .orderCreationFee, .transactionFee]
        
        let lamports = reduce(SolanaSDK.Lamports(0), {result, element in
            if !networkFeeTypes.contains(element.type) {
                return result
            }
            return result + element.lamports
        })
        
        let token = first(where: {networkFeeTypes.contains($0.type)})?.token ?? .nativeSolana
        
        return .init(
            type: .networkFee,
            lamports: lamports,
            token: token)
        {
            "\(lamports.convertToBalance(decimals: token.decimals).toString(maximumFractionDigits: 9)) \(token.symbol)"
        }
    }
}
