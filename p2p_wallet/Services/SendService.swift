//
//  SendServiceType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation
import RxSwift
import FeeRelayerSwift
import OrcaSwapSwift

protocol SendServiceType {
    func load() -> Completable
    func getFees() -> Single<SolanaSDK.Fee>
    func checkAccountValidation(account: String) -> Single<Bool>
    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendToken.Network
    ) -> Single<SolanaSDK.FeeAmount>
    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendToken.Network,
        payingFeeWallet: Wallet?
    ) -> Single<String>
    func isTestNet() -> Bool
}

class SendService: SendServiceType {
    @Injected private var solanaSDK: SolanaSDK
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var feeRelayerAPIClient: FeeRelayerAPIClientType
    @Injected private var relayService: FeeRelayerRelayType
    @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
    @Injected private var feeService: FeeServiceType
    
    func load() -> Completable {
        .zip(
            orcaSwap.load()
                .andThen(relayService.load()),
            feeService.load()
        )
        
    }
    
    func getFees() -> Single<SolanaSDK.Fee> {
        solanaSDK.getFees(commitment: nil)
    }
    
    func checkAccountValidation(account: String) -> Single<Bool> {
        solanaSDK.checkAccountValidation(account: account)
    }
    
    func isTestNet() -> Bool {
        solanaSDK.endpoint.network.isTestnet
    }
    
    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendToken.Network
    ) -> Single<SolanaSDK.FeeAmount> {
        guard let receiver = receiver else {
            return .just(.init(transaction: 0, accountBalances: 0))
        }

        switch network {
        case .bitcoin:
            return .just(
                .init(
                    transaction: 20000,
                    accountBalances: 0,
                    others: [
                        .init(amount: 0.0002, unit: "renBTC")
                    ]
                )
            )
        case .solana:
            return prepareForSendingToSolanaNetwork(
                from: wallet,
                receiver: receiver,
                amount: 10000, // placeholder
                payingFeeToken: nil,
                recentBlockhash: "FR1GgH83nmcEdoNXyztnpUL2G13KkUv6iwJPwVfnqEgW", // placeholder
                lamportsPerSignature: feeService.lamportsPerSignature, // cached lamportsPerSignature
                minRentExemption: feeService.minimumBalanceForRenExemption
            )
                .map {$0.expectedFee}
        }
    }
    
    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendToken.Network,
        payingFeeWallet: Wallet?
    ) -> Single<String> {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else {return .error(SolanaSDK.Error.other("Source wallet is not valid"))}
        // form request
        if receiver == sender {
            return .error(SolanaSDK.Error.other(L10n.youCanNotSendTokensToYourself))
        }
        
        // get paying fee token
        let payingFeeToken: FeeRelayer.Relay.TokenInfo?
        do {
            payingFeeToken = try getPayingFeeToken(payingFeeWallet: payingFeeWallet)
        } catch {
            return .error(error)
        }
        
        // detect network
        let request: Single<String>
        switch network {
        case .solana:
            request = prepareForSendingToSolanaNetwork(
                from: wallet,
                receiver: receiver,
                amount: amount.convertToBalance(decimals: wallet.token.decimals),
                payingFeeToken: payingFeeToken
            )
                .flatMap { [weak self] preparedTransaction in
                    guard let self = self else { throw SolanaSDK.Error.unknown }
                    
                    if let payingFeeToken = payingFeeToken,
                       payingFeeToken.mint != SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
                    {
                        // use fee relayer
                        return self.relayService.topUpAndRelayTransaction(
                            preparedTransaction: preparedTransaction,
                            payingFeeToken: payingFeeToken
                        )
                            .map {$0.first ?? ""}
                    } else {
                        // send normally, paid by SOL
                        return self.solanaSDK.serializeAndSend(
                            preparedTransaction: preparedTransaction,
                            isSimulation: false
                        )
                    }
                }
                .do(onSuccess: {
                    Logger.log(message: "\($0)", event: .response)
                }, onError: {
                    Logger.log(message: "\($0)", event: .error)
                })
            
        case .bitcoin:
            request = renVMBurnAndReleaseService.burn(
                recipient: receiver,
                amount: amount
            )
        }
        return request
    }
    
    private func prepareForSendingToSolanaNetwork(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        payingFeeToken: FeeRelayer.Relay.TokenInfo?,
        recentBlockhash: String? = nil,
        lamportsPerSignature: SolanaSDK.Lamports? = nil,
        minRentExemption: SolanaSDK.Lamports? = nil
    ) -> Single<SolanaSDK.PreparedTransaction> {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else {return .error(SolanaSDK.Error.other("Source wallet is not valid"))}
        // form request
        if receiver == sender {
            return .error(SolanaSDK.Error.other(L10n.youCanNotSendTokensToYourself))
        }
        
        // prepare fee payer
        let feePayerRequest: Single<String?>
        let useFeeRelayer: Bool
        
        if let payingFeeToken = payingFeeToken,
           payingFeeToken.mint != SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
        {
            feePayerRequest = feeRelayerAPIClient.getFeePayerPubkey()
                .map(Optional.init)
            useFeeRelayer = true
        } else {
            feePayerRequest = .just(nil)
            useFeeRelayer = false
        }
        
        // request
        let createSendRequest: (String?) throws -> Single<SolanaSDK.PreparedTransaction> = {[weak self] feePayer in
            guard let self = self else {return .error(SolanaSDK.Error.unknown)}
            let feePayer = feePayer == nil ? nil: try SolanaSDK.PublicKey(string: feePayer)
            
            if wallet.isNativeSOL {
                return self.solanaSDK.prepareSendingNativeSOL(
                    to: receiver,
                    amount: amount,
                    feePayer: feePayer,
                    recentBlockhash: recentBlockhash,
                    lamportsPerSignature: lamportsPerSignature
                )
            }
            
            // other tokens
            else {
                return self.solanaSDK.prepareSendingSPLTokens(
                    mintAddress: wallet.mintAddress,
                    decimals: wallet.token.decimals,
                    from: sender,
                    to: receiver,
                    amount: amount,
                    feePayer: feePayer,
                    transferChecked: useFeeRelayer, // create transferChecked instruction when using fee relayer
                    recentBlockhash: recentBlockhash,
                    lamportsPerSignature: lamportsPerSignature,
                    minRentExemption: minRentExemption
                ).map {$0.preparedTransaction}
            }
        }
        
        return feePayerRequest
            .flatMap(createSendRequest)
    }
    
    private func getPayingFeeToken(payingFeeWallet: Wallet?) throws -> FeeRelayer.Relay.TokenInfo? {
        if let payingFeeWallet = payingFeeWallet {
            guard let address = payingFeeWallet.pubkey else {
                throw SolanaSDK.Error.other("Paying fee wallet is not valid")
            }
            return .init(address: address, mint: payingFeeWallet.mintAddress)
        }
        return nil
    }
}
