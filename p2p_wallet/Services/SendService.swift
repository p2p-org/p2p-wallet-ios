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
    var relayMethod: SendTokenRelayMethod { get }
    
    func load() -> Completable
    func checkAccountValidation(account: String) -> Single<Bool>
    func isTestNet() -> Bool
    
    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendToken.Network,
        payingFeeToken: FeeRelayer.Relay.TokenInfo?
    ) -> Single<SolanaSDK.FeeAmount?>
    func getFeesInPayingToken(
        feeInSOL: SolanaSDK.Lamports,
        payingFeeWallet: Wallet
    ) -> Single<SolanaSDK.Lamports?>
    
    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendToken.Network,
        payingFeeWallet: Wallet?
    ) -> Single<String>
}

class SendService: SendServiceType {
    let relayMethod: SendTokenRelayMethod
    @Injected private var solanaSDK: SolanaSDK
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var feeRelayerAPIClient: FeeRelayerAPIClientType
    @Injected private var relayService: FeeRelayerRelayType
    @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
    @Injected private var feeService: FeeServiceType
    private var cachedFeePayerPubkey: String?
    
    init(relayMethod: SendTokenRelayMethod) {
        self.relayMethod = relayMethod
    }
    
    // MARK: - Methods
    func load() -> Completable {
        var completables = [feeService.load()]
        
        if relayMethod == .relay {
            completables.append(orcaSwap.load().andThen(relayService.load()))
        }
        
        return .zip(completables)
    }
    
    func checkAccountValidation(account: String) -> Single<Bool> {
        solanaSDK.checkAccountValidation(account: account)
    }
    
    func isTestNet() -> Bool {
        solanaSDK.endpoint.network.isTestnet
    }
    
    // MARK: - Fees calculator
    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendToken.Network,
        payingFeeToken: FeeRelayer.Relay.TokenInfo?
    ) -> Single<SolanaSDK.FeeAmount?> {
        guard let receiver = receiver else {
            return .just(nil)
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
            switch relayMethod {
            case .relay:
                return prepareForSendingToSolanaNetworkViaRelayMethod(
                    from: wallet,
                    receiver: receiver,
                    amount: 10000, // placeholder
                    payingFeeToken: payingFeeToken,
                    recentBlockhash: "FR1GgH83nmcEdoNXyztnpUL2G13KkUv6iwJPwVfnqEgW", // placeholder
                    lamportsPerSignature: feeService.lamportsPerSignature, // cached lamportsPerSignature
                    minRentExemption: feeService.minimumBalanceForRenExemption,
                    usingCachedFeePayerPubkey: true
                )
                    .map { [weak self] preparedTransaction in
                        guard let self = self else {throw SolanaSDK.Error.unknown}
                        return self.relayService.calculateFee(preparedTransaction: preparedTransaction)
                    }
            case .reward:
                return .just(.zero)
            }
        }
    }
    
    func getFeesInPayingToken(
        feeInSOL: SolanaSDK.Lamports,
        payingFeeWallet: Wallet
    ) -> Single<SolanaSDK.Lamports?> {
        guard relayMethod == .relay else {return .just(nil)}
        guard let payingFeeWalletAddress = payingFeeWallet.pubkey else {return .just(nil)}
        if payingFeeWallet.isNativeSOL {return .just(feeInSOL)}
        return relayService.calculateFeeInPayingToken(
            feeInSOL: feeInSOL,
            payingFeeToken: .init(address: payingFeeWalletAddress, mint: payingFeeWallet.mintAddress)
        )
    }
    
    // MARK: - Send method
    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendToken.Network,
        payingFeeWallet: Wallet? // nil for relayMethod == .reward
    ) -> Single<String> {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else {return .error(SolanaSDK.Error.other("Source wallet is not valid"))}
        // form request
        if receiver == sender {
            return .error(SolanaSDK.Error.other(L10n.youCanNotSendTokensToYourself))
        }
        
        // detect network
        let request: Single<String>
        switch network {
        case .solana:
            switch relayMethod {
            case .relay:
                request = sendToSolanaBCViaRelayMethod(
                    from: wallet,
                    receiver: receiver,
                    amount: amount,
                    payingFeeWallet: payingFeeWallet
                )
            case .reward:
                request = sendToSolanaBCViaRewardMethod(
                    from: wallet,
                    receiver: receiver,
                    amount: amount
                )
            }
        case .bitcoin:
            request = renVMBurnAndReleaseService.burn(
                recipient: receiver,
                amount: amount
            )
        }
        return request
    }
    
    // MARK: - Relay method
    private func sendToSolanaBCViaRelayMethod(
        from wallet: Wallet,
        receiver: String,
        amount: SolanaSDK.Lamports,
        payingFeeWallet: Wallet?
    ) -> Single<String> {
        // get paying fee token
        let payingFeeToken = try? getPayingFeeToken(payingFeeWallet: payingFeeWallet)
        
        return prepareForSendingToSolanaNetworkViaRelayMethod(
            from: wallet,
            receiver: receiver,
            amount: amount.convertToBalance(decimals: wallet.token.decimals),
            payingFeeToken: payingFeeToken
        )
            .flatMap { [weak self] preparedTransaction in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                
                if payingFeeToken?.mint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
                    // send normally, paid by SOL
                    return self.solanaSDK.serializeAndSend(
                        preparedTransaction: preparedTransaction,
                        isSimulation: false
                    )
                } else {
                    // use fee relayer
                    return self.relayService.topUpAndRelayTransaction(
                        preparedTransaction: preparedTransaction,
                        payingFeeToken: payingFeeToken
                    )
                        .map {$0.first ?? ""}
                }
            }
            .do(onSuccess: {
                Logger.log(message: "\($0)", event: .response)
            }, onError: {
                Logger.log(message: "\($0)", event: .error)
            })
    }
    
    private func prepareForSendingToSolanaNetworkViaRelayMethod(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        payingFeeToken: FeeRelayer.Relay.TokenInfo?,
        recentBlockhash: String? = nil,
        lamportsPerSignature: SolanaSDK.Lamports? = nil,
        minRentExemption: SolanaSDK.Lamports? = nil,
        usingCachedFeePayerPubkey: Bool = false
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
        
        if payingFeeToken?.mint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
            feePayerRequest = .just(nil)
            useFeeRelayer = false
        } else {
            if usingCachedFeePayerPubkey, let pubkey = cachedFeePayerPubkey {
                feePayerRequest = .just(pubkey)
            } else {
                feePayerRequest = feeRelayerAPIClient.getFeePayerPubkey()
                    .map(Optional.init)
                    .do(onSuccess: {[weak self] in self?.cachedFeePayerPubkey = $0})
            }
            useFeeRelayer = true
        }
        
        return feePayerRequest
            .flatMap { [weak self] feePayer in
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
    
    // MARK: - Compensation method
    private func sendToSolanaBCViaRewardMethod(
        from wallet: Wallet,
        receiver: String,
        amount: SolanaSDK.Lamports
    ) -> Single<String> {
        guard let owner = solanaSDK.accountStorage.account,
              let sender = wallet.pubkey
        else {return .error(SolanaSDK.Error.unauthorized)}
        return solanaSDK.getRecentBlockhash(commitment: nil)
            .flatMap {[weak self] recentBlockhash -> Single<((SolanaSDK.PreparedTransaction, String?), String)> in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                return self.prepareForSendingToSolanaNetworkViaRewardMethod(
                    from: wallet,
                    receiver: receiver,
                    amount: amount.convertToBalance(decimals: wallet.token.decimals),
                    recentBlockhash: recentBlockhash
                )
                    .map {($0, recentBlockhash)}
            }
            .flatMap { [weak self] params, recentBlockhash in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                // get signature
                guard let data = params.0.transaction.findSignature(pubkey: owner.publicKey)?.signature
                else { throw SolanaSDK.Error.other("Signature not found")}
                
                let authoritySignature = Base58.encode(data.bytes)
                
                let request: Single<String>
                if wallet.isNativeSOL {
                    request = self.feeRelayerAPIClient.sendTransaction(
                        .rewardTransferSOL(
                            .init(
                                sender: sender,
                                recipient: receiver,
                                amount: amount,
                                signature: authoritySignature,
                                blockhash: recentBlockhash
                            )
                        )
                    )
                } else {
                    request = self.feeRelayerAPIClient.sendTransaction(
                        .rewardTransferSPLToken(
                            .init(
                                sender: sender,
                                recipient: params.1!,
                                mintAddress: wallet.mintAddress,
                                authority: owner.publicKey.base58EncodedString,
                                amount: amount,
                                decimals: wallet.token.decimals,
                                signature: authoritySignature,
                                blockhash: recentBlockhash
                            )
                        )
                    )
                }
                
                return request
                    .do(onSuccess: {
                        Logger.log(message: "\($0)", event: .response)
                    }, onError: {
                        Logger.log(message: "\($0)", event: .error)
                    })
            }
    }
    
    private func prepareForSendingToSolanaNetworkViaRewardMethod(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        recentBlockhash: String? = nil,
        lamportsPerSignature: SolanaSDK.Lamports? = nil,
        minRentExemption: SolanaSDK.Lamports? = nil,
        usingCachedFeePayerPubkey: Bool = false
    ) -> Single<(SolanaSDK.PreparedTransaction, String?)> {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else {return .error(SolanaSDK.Error.other("Source wallet is not valid"))}
        // form request
        if receiver == sender {
            return .error(SolanaSDK.Error.other(L10n.youCanNotSendTokensToYourself))
        }
        
        // prepare fee payer
        let feePayerRequest: Single<String?>
        if usingCachedFeePayerPubkey, let pubkey = cachedFeePayerPubkey {
            feePayerRequest = .just(pubkey)
        } else {
            feePayerRequest = feeRelayerAPIClient.getFeePayerPubkey()
                .map(Optional.init)
                .do(onSuccess: {[weak self] in self?.cachedFeePayerPubkey = $0})
        }
        
        return feePayerRequest
            .flatMap { [weak self] feePayer in
                guard let self = self else {return .error(SolanaSDK.Error.unknown)}
                let feePayer = feePayer == nil ? nil: try SolanaSDK.PublicKey(string: feePayer)
                
                if wallet.isNativeSOL {
                    return self.solanaSDK.prepareSendingNativeSOL(
                        to: receiver,
                        amount: amount,
                        feePayer: feePayer,
                        recentBlockhash: recentBlockhash,
                        lamportsPerSignature: lamportsPerSignature
                    ).map {($0, nil)}
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
                        transferChecked: true, // create transferChecked instruction when using fee relayer
                        recentBlockhash: recentBlockhash,
                        lamportsPerSignature: lamportsPerSignature,
                        minRentExemption: minRentExemption
                    ).map {($0.preparedTransaction, $0.realDestination)}
                }
            }
    }
}
