//
//  SendService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import FeeRelayerSwift
import OrcaSwapSwift
import RenVMSwift
import Resolver
import RxSwift
import SolanaSwift

class SendService: SendServiceType {
    let relayMethod: SendTokenRelayMethod

    @Injected var accountStorage: SolanaAccountStorage
    @Injected var solanaAPIClient: SolanaAPIClient
    @Injected var blockchainClient: BlockchainClient
    @Injected var orcaSwap: OrcaSwapType
    @Injected var feeRelayer: FeeRelayer
    @Injected var feeRelayerAPIClient: FeeRelayerAPIClient
    @Injected var contextManager: FeeRelayerContextManager

    @Injected private var renVMBurnAndReleaseService: BurnAndReleaseService
    @Injected private var feeService: FeeServiceType
    @Injected private var walletsRepository: WalletsRepository

    init(relayMethod: SendTokenRelayMethod) {
        self.relayMethod = relayMethod
    }

    // MARK: - Methods

    func load() async throws {
        let _ = try await(
            orcaSwap.load(),
            contextManager.update()
        )
    }

    func checkAccountValidation(account: String) async throws -> Bool {
        try await solanaAPIClient.checkAccountValidation(account: account)
    }

    func isTestNet() -> Bool {
        solanaAPIClient.endpoint.network.isTestnet
    }

    // MARK: - Fees calculator

    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendToken.Network,
        payingTokenMint: String?
    ) async throws -> FeeAmount? {
        switch network {
        case .bitcoin:
            return FeeAmount(
                transaction: 20000,
                accountBalances: 0,
                others: [
                    .init(amount: 0.0002, unit: "renBTC"),
                ]
            )
        case .solana:
            guard let receiver = receiver else {
                return nil
            }

            switch relayMethod {
            case .relay:
                return try await getFeeViaRelayMethod(
                    try await contextManager.getCurrentContext(),
                    from: wallet,
                    receiver: receiver,
                    payingTokenMint: payingTokenMint
                )
            case .reward:
                return FeeAmount.zero
            }
        }
    }

    func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet] {
        try await Single.zip(
            walletsRepository.getWallets()
                .filter { ($0.lamports ?? 0) > 0 }
                .map { wallet -> Single<Wallet?> in
                    if wallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
                        return (wallet.lamports ?? 0) >= feeInSOL.total ? .just(wallet) : .just(nil)
                    }

                    return Single.async {
                        try await self.feeRelayer.feeCalculator.calculateFeeInPayingToken(
                            orcaSwap: self.orcaSwap,
                            feeInSOL: feeInSOL,
                            payingFeeTokenMint: try PublicKey(string: wallet.mintAddress)
                        )
                    }
                    .map { ($0?.total ?? 0) <= (wallet.lamports ?? 0) }
                    .map { $0 ? wallet : nil }
                    .catchAndReturn(nil)
                }
        )
            .map { $0.compactMap { $0 }}
            .value
    }

    func getFeesInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeWallet: Wallet
    ) async throws -> FeeAmount? {
        guard relayMethod == .relay else { return nil }

        if payingFeeWallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
            return feeInSOL
        }

        return try await feeRelayer.feeCalculator.calculateFeeInPayingToken(
            orcaSwap: orcaSwap,
            feeInSOL: feeInSOL,
            payingFeeTokenMint: try PublicKey(string: payingFeeWallet.mintAddress)
        )
    }

    func getFreeTransactionFeeLimit() async throws -> UsageStatus {
        try await contextManager.getCurrentContext().usageStatus
    }

    // MARK: - Send method

    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendToken.Network,
        payingFeeWallet: Wallet? // nil for relayMethod == .reward
    ) async throws -> String {
        try await contextManager.update()

        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else { throw Error.invalidSourceWallet }
        // form request
        if receiver == sender {
            throw Error.sendToYourself
        }

        // detect network
        switch network {
        case .solana:
            switch relayMethod {
            case .relay:
                return try await sendToSolanaBCViaRelayMethod(
                    try await contextManager.getCurrentContext(),
                    from: wallet,
                    receiver: receiver,
                    amount: amount,
                    payingFeeWallet: payingFeeWallet
                )
            case .reward:
                return try await sendToSolanaBCViaRewardMethod(
                    try await contextManager.getCurrentContext(),
                    from: wallet,
                    receiver: receiver,
                    amount: amount
                )
            }
        case .bitcoin:
            return try await renVMBurnAndReleaseService.burnAndRelease(
                recipient: receiver,
                amount: amount
            )
        }
    }
}
