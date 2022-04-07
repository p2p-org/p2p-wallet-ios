//
//  SendService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import FeeRelayerSwift
import OrcaSwapSwift
import RxSwift

class SendService: SendServiceType {
    private let locker = NSLock()
    let relayMethod: SendTokenRelayMethod
    @Injected private var solanaSDK: SolanaSDK
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var feeRelayerAPIClient: FeeRelayerAPIClientType
    @Injected private var relayService: FeeRelayerRelayType
    @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
    @Injected private var feeService: FeeServiceType
    @Injected private var walletsRepository: WalletsRepository
    private var cachedFeePayerPubkey: String?
    private var cachedPoolsSPLToSOL = [String: [OrcaSwap.PoolsPair]]() // [Mint: Pools]

    init(relayMethod: SendTokenRelayMethod) {
        self.relayMethod = relayMethod
    }

    // MARK: - Methods

    func load() -> Completable {
        var completables = [feeService.load()]

        if relayMethod == .relay {
            completables.append(
                orcaSwap.load()
                    .andThen(relayService.load())
                    .andThen(
                        // load all pools
                        Single.zip(
                            walletsRepository.getWallets()
                                .filter { ($0.lamports ?? 0) > 0 }
                                .map { wallet in
                                    orcaSwap.getTradablePoolsPairs(
                                        fromMint: wallet.mintAddress,
                                        toMint: SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString
                                    )
                                        .do(onSuccess: { [weak self] poolsPair in
                                            self?.locker.lock()
                                            self?.cachedPoolsSPLToSOL[wallet.mintAddress] = poolsPair
                                            self?.locker.unlock()
                                        })
                                }
                        )
                            .asCompletable()
                    )
            )
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
        payingTokenMint: String?
    ) -> Single<SolanaSDK.FeeAmount?> {
        switch network {
        case .bitcoin:
            return .just(
                .init(
                    transaction: 20000,
                    accountBalances: 0,
                    others: [
                        .init(amount: 0.0002, unit: "renBTC"),
                    ]
                )
            )
        case .solana:
            guard let receiver = receiver else {
                return .just(nil)
            }

            switch relayMethod {
            case .relay:
                // get fee calculator
                guard let lamportsPerSignature = relayService.cache.lamportsPerSignature,
                      let minRentExemption = relayService.cache.minimumTokenAccountBalance
                else { return .error(FeeRelayer.Error.unknown) }

                var transactionFee: UInt64 = 0

                // owner's signature
                transactionFee += lamportsPerSignature

                // feePayer's signature
                transactionFee += lamportsPerSignature

                let isUnregisteredAsocciatedTokenRequest: Single<Bool>
                if wallet.mintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
                    isUnregisteredAsocciatedTokenRequest = .just(false)
                } else {
                    isUnregisteredAsocciatedTokenRequest = solanaSDK.findSPLTokenDestinationAddress(
                        mintAddress: wallet.mintAddress,
                        destinationAddress: receiver
                    )
                        .map(\.isUnregisteredAsocciatedToken)
                }

                // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
                if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(payingTokenMint: payingTokenMint) {
                    // subtract the fee payer signature cost
                    transactionFee -= lamportsPerSignature
                }

                return isUnregisteredAsocciatedTokenRequest
                    .map {
                        SolanaSDK.FeeAmount(
                            transaction: transactionFee,
                            accountBalances: $0 ? minRentExemption : 0
                        )
                    }
                    .flatMap { [weak self] expectedFee in
                        guard let self = self else { throw SolanaSDK.Error.unknown }

                        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
                        if self.isFreeTransactionNotAvailableAndUserIsPayingWithSOL(payingTokenMint: payingTokenMint) {
                            return .just(expectedFee)
                        }

                        return self.relayService.calculateNeededTopUpAmount(
                            expectedFee: expectedFee,
                            payingTokenMint: payingTokenMint
                        )
                            .map(Optional.init)
                    }
            case .reward:
                return .just(.zero)
            }
        }
    }

    func getAvailableWalletsToPayFee(feeInSOL: SolanaSDK.FeeAmount) -> Single<[Wallet]> {
        Single.zip(
            walletsRepository.getWallets()
                .filter { ($0.lamports ?? 0) > 0 }
                .map { wallet -> Single<Wallet?> in
                    if wallet.mintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
                        return (wallet.lamports ?? 0) >= feeInSOL.total ? .just(wallet) : .just(nil)
                    }
                    return relayService.calculateFeeInPayingToken(
                        feeInSOL: feeInSOL,
                        payingFeeTokenMint: wallet.mintAddress
                    )
                        .map { ($0?.total ?? 0) <= (wallet.lamports ?? 0) }
                        .map { $0 ? wallet : nil }
                        .catchAndReturn(nil)
                }
        )
            .map { $0.compactMap { $0 }}
    }

    func getFeesInPayingToken(
        feeInSOL: SolanaSDK.FeeAmount,
        payingFeeWallet: Wallet
    ) -> Single<SolanaSDK.FeeAmount?> {
        guard relayMethod == .relay else { return .just(nil) }
        if payingFeeWallet.mintAddress == SolanaSDK.PublicKey.wrappedSOLMint
            .base58EncodedString { return .just(feeInSOL) }
        return relayService.calculateFeeInPayingToken(
            feeInSOL: feeInSOL,
            payingFeeTokenMint: payingFeeWallet.mintAddress
        )
    }

    func getFreeTransactionFeeLimit() -> Single<FeeRelayer.Relay.FreeTransactionFeeLimit> {
        relayService.getFreeTransactionFeeLimit()
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
        guard let sender = wallet.pubkey else { return .error(SolanaSDK.Error.other("Source wallet is not valid")) }
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
            .flatMap { [weak self] preparedTransaction, useFeeRelayer in
                guard let self = self else { throw SolanaSDK.Error.unknown }

                if useFeeRelayer {
                    // using fee relayer
                    return self.relayService.topUpAndRelayTransaction(
                        preparedTransaction: preparedTransaction,
                        payingFeeToken: payingFeeToken
                    )
                        .map { $0.first ?? "" }
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
    ) -> Single<(preparedTransaction: SolanaSDK.PreparedTransaction, useFeeRelayer: Bool)> {
        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else { return .error(SolanaSDK.Error.other("Source wallet is not valid")) }
        // form request
        if receiver == sender {
            return .error(SolanaSDK.Error.other(L10n.youCanNotSendTokensToYourself))
        }

        // prepare fee payer
        let feePayerRequest: Single<String?>
        let useFeeRelayer: Bool

        // when free transaction is not available and user is paying with sol, let him do this the normal way (don't use fee relayer)
        if isFreeTransactionNotAvailableAndUserIsPayingWithSOL(payingTokenMint: payingFeeToken?.mint) {
            feePayerRequest = .just(nil)
            useFeeRelayer = false
        }

        // otherwise send to fee relayer
        else {
            if usingCachedFeePayerPubkey, let pubkey = cachedFeePayerPubkey {
                feePayerRequest = .just(pubkey)
            } else {
                feePayerRequest = feeRelayerAPIClient.getFeePayerPubkey()
                    .map(Optional.init)
                    .do(onSuccess: { [weak self] in self?.cachedFeePayerPubkey = $0 })
            }
            useFeeRelayer = true
        }

        return feePayerRequest
            .flatMap { [weak self] feePayer in
                guard let self = self else { return .error(SolanaSDK.Error.unknown) }
                let feePayer = feePayer == nil ? nil : try SolanaSDK.PublicKey(string: feePayer)

                let request: Single<SolanaSDK.PreparedTransaction>
                if wallet.isNativeSOL {
                    request = self.solanaSDK.prepareSendingNativeSOL(
                        to: receiver,
                        amount: amount,
                        feePayer: feePayer,
                        recentBlockhash: recentBlockhash,
                        lamportsPerSignature: lamportsPerSignature
                    )
                }

                // other tokens
                else {
                    request = self.solanaSDK.prepareSendingSPLTokens(
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
                    ).map(\.preparedTransaction)
                }

                return request.map { (preparedTransaction: $0, useFeeRelayer: useFeeRelayer) }
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
        else { return .error(SolanaSDK.Error.unauthorized) }
        return solanaSDK.getRecentBlockhash(commitment: nil)
            .flatMap { [weak self] recentBlockhash -> Single<((SolanaSDK.PreparedTransaction, String?), String)> in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                return self.prepareForSendingToSolanaNetworkViaRewardMethod(
                    from: wallet,
                    receiver: receiver,
                    amount: amount.convertToBalance(decimals: wallet.token.decimals),
                    recentBlockhash: recentBlockhash
                )
                    .map { ($0, recentBlockhash) }
            }
            .flatMap { [weak self] params, recentBlockhash in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                // get signature
                guard let data = params.0.transaction.findSignature(pubkey: owner.publicKey)?.signature
                else { throw SolanaSDK.Error.other("Signature not found") }

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
                    .map { $0.replacingOccurrences(of: "\"", with: "") }
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
        guard let sender = wallet.pubkey else { return .error(SolanaSDK.Error.other("Source wallet is not valid")) }
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
                .do(onSuccess: { [weak self] in self?.cachedFeePayerPubkey = $0 })
        }

        return feePayerRequest
            .flatMap { [weak self] feePayer in
                guard let self = self else { return .error(SolanaSDK.Error.unknown) }
                let feePayer = feePayer == nil ? nil : try SolanaSDK.PublicKey(string: feePayer)

                if wallet.isNativeSOL {
                    return self.solanaSDK.prepareSendingNativeSOL(
                        to: receiver,
                        amount: amount,
                        feePayer: feePayer,
                        recentBlockhash: recentBlockhash,
                        lamportsPerSignature: lamportsPerSignature
                    ).map { ($0, nil) }
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
                    ).map { ($0.preparedTransaction, $0.realDestination) }
                }
            }
    }

    private func isFreeTransactionNotAvailableAndUserIsPayingWithSOL(
        payingTokenMint: String?
    ) -> Bool {
        let expectedTransactionFee = (relayService.cache.lamportsPerSignature ?? 5000) * 2
        return payingTokenMint == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString &&
            relayService.cache.freeTransactionFeeLimit?
            .isFreeTransactionFeeAvailable(transactionFee: expectedTransactionFee) == false
    }
}
