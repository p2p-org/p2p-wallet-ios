//
//  SerumSwap+SwapProviderType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/08/2021.
//  TO USE THIS, ADD TO TARGET MEMBERSHIP

import Foundation
import RxSwift

extension SerumSwap: SwapProviderType {
    func isFeeRelayerEnabled(
        source: Wallet?,
        destination: Wallet?
    ) -> Bool {
        // TODO: - Later
        false
    }
    
    func calculateFees(
        sourceWallet: Wallet?,
        destinationWallet: Wallet?,
        lamportsPerSignature: SolanaSDK.Lamports?,
        creatingAccountFee: SolanaSDK.Lamports?
    ) -> Single<[PayingFee]> {
        var fees = [PayingFee]()
        
        // liquidity provider fee
        fees.append(
            .init(
                type: .liquidityProviderFee,
                lamports: 0,
                token: .unsupported(mint: nil),
                toString: {
                    (BASE_TAKER_FEE_BPS*100).toString() + "%"
                }
            )
        )
        
        guard let sourceWallet = sourceWallet,
              let destinationWallet = destinationWallet,
              let lamportsPerSignature = lamportsPerSignature,
              let creatingAccountFee = creatingAccountFee
        else {return .just(fees)}
        
        let isPayingWithSOL = !isFeeRelayerEnabled(source: sourceWallet, destination: destinationWallet)
        
        let networkFeeRequest = calculateNetworkFee(
            fromWallet: sourceWallet,
            toWallet: destinationWallet,
            lamportsPerSignature: lamportsPerSignature,
            minRentExemption: creatingAccountFee
        )
        
        return networkFeeRequest
            .flatMap {networkFees in
                // if paying directly with SOL
                if isPayingWithSOL {
                    fees.append(contentsOf: [
                        .init(type: .accountCreationFee(token: nil), lamports: networkFees.accountCreationFee, token: .nativeSolana, toString: nil),
                        .init(type: .orderCreationFee, lamports: networkFees.serumOrderCreationFee, token: .nativeSolana, toString: nil),
                        .init(type: .transactionFee, lamports: networkFees.transactionFee, token: .nativeSolana, toString: nil)
                    ])
                    return .just(fees)
                }
                
                // convert fee from SOL to amount in source token
                // TODO: - Check: look for sourceToken/SOL price and send to fee-relayer
                else {
                    do {
                        let fromMint = try SolanaSDK.PublicKey(string: sourceWallet.mintAddress)
                        return loadFair(fromMint: fromMint, toMint: .solMint)
                            .map { rate -> (SolanaSDK.Lamports, SolanaSDK.Lamports, SolanaSDK.Lamports) in
                                let accountCreationFee = calculateNeededInputAmount(
                                    forReceivingEstimatedAmount: networkFees.accountCreationFee
                                        .convertToBalance(decimals: 9),
                                    rate: rate,
                                    slippage: 0.01
                                )
                                let orderCreationFee = calculateNeededInputAmount(
                                    forReceivingEstimatedAmount: networkFees.serumOrderCreationFee
                                        .convertToBalance(decimals: 9),
                                    rate: rate,
                                    slippage: 0.01
                                )
                                let transactionFee = calculateNeededInputAmount(
                                    forReceivingEstimatedAmount: networkFees.transactionFee
                                        .convertToBalance(decimals: 9),
                                    rate: rate,
                                    slippage: 0.01
                                )
                                let decimals = sourceWallet.token.decimals
                                return (
                                    accountCreationFee?.toLamport(decimals: decimals) ?? 0,
                                    orderCreationFee?.toLamport(decimals: decimals) ?? 0,
                                    transactionFee?.toLamport(decimals: decimals) ?? 0
                                )
                            }
                            .map { neededAmounts -> [PayingFee] in
                                fees.append(contentsOf: [
                                    .init(type: .accountCreationFee(token: nil), lamports: neededAmounts.0, token: sourceWallet.token, toString: nil),
                                    .init(type: .orderCreationFee, lamports: neededAmounts.1, token: sourceWallet.token, toString: nil),
                                    .init(type: .transactionFee, lamports: neededAmounts.2, token: sourceWallet.token, toString: nil)
                                ])
                                return fees
                            }
                    } catch {
                        return .error(error)
                    }
                }
            }
    }
    
    func calculateMinOrderSize(
        fromMint: String,
        toMint: String
    ) -> Single<Double> {
        loadMinOrderSize(fromMint: fromMint, toMint: toMint)
    }
    
    func calculateAvailableAmount(
        sourceWallet: Wallet?,
        fees: [PayingFee]?
    ) -> Double? {
        guard let sourceWallet = sourceWallet else {return nil}
        guard let fees = fees else {return sourceWallet.amount}
        guard var amount = sourceWallet.lamports else {return nil}
        
        // available amount is remainder when amount subtracts all fees that have to pay by current wallet
        for fee in fees where fee.token.address == sourceWallet.token.address {
            if amount > fee.lamports {
                amount -= fee.lamports
            } else {
                amount = 0
            }
        }
        
        return amount.convertToBalance(decimals: sourceWallet.token.decimals)
    }
    
    func calculateEstimatedAmount(
        inputAmount: Double?,
        rate: Double?,
        slippage: Double?
    ) -> Double? {
        guard let inputAmount = inputAmount,
              let fair = rate,
              fair != 0
        else {return nil}
        return FEE_MULTIPLIER * (inputAmount / fair)
    }
    
    func calculateNeededInputAmount(
        forReceivingEstimatedAmount estimatedAmount: Double?,
        rate: Double?,
        slippage: Double?
    ) -> Double? {
        guard let estimatedAmount = estimatedAmount,
              let fair = rate,
              fair != 0
        else {return nil}
        return estimatedAmount * fair / FEE_MULTIPLIER
    }
    
    func loadPrice(
        fromMint: String,
        toMint: String
    ) -> Single<Double> {
        guard let fromMint = try? Self.PublicKey(string: fromMint),
              let toMint = try? Self.PublicKey(string: toMint)
        else {return .error(SolanaSDK.Error.unknown)}
        return loadFair(fromMint: fromMint, toMint: toMint)
    }
    
    func logoView() -> UIView {
        UIImageView(width: 24, height: 24, image: .serumLogo, tintColor: .textBlack)
    }
}
