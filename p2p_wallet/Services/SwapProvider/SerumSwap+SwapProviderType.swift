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
        
        var feeInSOL: SolanaSDK.Lamports = 0
        
        // if source token is native, a fee for creating wrapped SOL is needed, thus a fee for new account's signature (not associated token address) is also needed
        if sourceWallet.token.isNative {
            feeInSOL += creatingAccountFee + lamportsPerSignature
        }
        
        // if destination wallet is a wrapped sol or not yet created, a fee for creating it is needed, as new address is an associated token address, the signature fee is NOT needed
        if destinationWallet.token.address == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString ||
            destinationWallet.pubkey == nil
        {
            feeInSOL += creatingAccountFee
        }
        
        // fee for creating new open order
        feeInSOL += creatingAccountFee + lamportsPerSignature
        
        // define if paying directly with SOL or paying with source token through fee-relayer
        let isPayingWithSOL = !isFeeRelayerEnabled(source: sourceWallet, destination: destinationWallet)
        
        // if paying directly with SOL
        if isPayingWithSOL {
            feeInSOL += lamportsPerSignature
            fees[.default] = .init(lamports: feeInSOL, token: .nativeSolana, toString: nil)
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
                            forReceivingEstimatedAmount: feeInSOL.convertToBalance(decimals: 9),
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
