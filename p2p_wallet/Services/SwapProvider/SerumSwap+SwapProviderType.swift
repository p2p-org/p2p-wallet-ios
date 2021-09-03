//
//  SerumSwap+SwapProviderType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/08/2021.
//

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
    ) -> Single<[FeeType: SwapFee]> {
        var fees = [FeeType: SwapFee]()
        fees[.liquidityProvider] = .init(
            lamports: 0,
            token: .unsupported(mint: nil),
            toString: {
                (BASE_TAKER_FEE_BPS*100).toString() + "%"
            }
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
            minRentExemption: creatingAccountFee,
            isPayingWithSOL: isPayingWithSOL
        )
        
        return networkFeeRequest
            .flatMap {networkFee in
                // if paying directly with SOL
                if isPayingWithSOL {
                    fees[.default] = .init(lamports: networkFee, token: .nativeSolana, toString: nil)
                    return .just(fees)
                }
                
                // convert fee from SOL to amount in source token
                // TODO: - Check: look for sourceToken/SOL price and send to fee-relayer
                else {
                    do {
                        let fromMint = try SolanaSDK.PublicKey(string: sourceWallet.mintAddress)
                        return loadFair(fromMint: fromMint, toMint: .solMint)
                            .map {
                                calculateNeededInputAmount(
                                    forReceivingEstimatedAmount: networkFee.convertToBalance(decimals: 9),
                                    rate: $0,
                                    slippage: 0.01
                                )
                            }
                            .map { neededAmount -> [FeeType: SwapFee] in
                                guard let lamports = neededAmount?.toLamport(decimals: sourceWallet.token.decimals)
                                else {return [:]}
                                fees[.default] = .init(lamports: lamports, token: sourceWallet.token, toString: nil)
                                return fees
                            }
                    } catch {
                        return .error(error)
                    }
                }
            }
    }
    
    func calculateAvailableAmount(
        sourceWallet: Wallet?,
        fee: SwapFee?
    ) -> Double? {
        guard let sourceWallet = sourceWallet else {return nil}
        guard let fee = fee else {return sourceWallet.amount}
        guard var amount = sourceWallet.lamports else {return nil}
        
        if fee.token.symbol == "SOL" {
            if sourceWallet.token.isNative {
                amount -= fee.lamports
            }
        } else if fee.token.symbol == sourceWallet.token.symbol {
            amount -= fee.lamports
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
