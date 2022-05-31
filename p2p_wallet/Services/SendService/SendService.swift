//
//  SendService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import FeeRelayerSwift
import OrcaSwapSwift
import Resolver
import RxSwift
import SolanaSwift

class SendService: SendServiceType {
    private let locker = NSLock()
    let relayMethod: SendTokenRelayMethod
    @Injected var solanaAPIClient: SolanaAPIClient
    @Injected private var orcaSwap: OrcaSwapType
    @Injected var feeRelayerAPIClient: FeeRelayerAPIClient
    @Injected var relayService: FeeRelayer
    @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
    @Injected private var feeService: FeeServiceType
    @Injected private var walletsRepository: WalletsRepository

    let cache = Cache()

    init(relayMethod: SendTokenRelayMethod) {
        self.relayMethod = relayMethod
    }

    // MARK: - Methods

    func load() -> Completable {
        Completable.async { [weak self] in
            guard let self = self else { throw SolanaError.unknown }
            try await self.orcaSwap.load()
            try await withThrowingTaskGroup(of: (String, [PoolsPair]).self) { group in
                for wallet in self.walletsRepository.getWallets().filter({ ($0.lamports ?? 0) > 0 }) {
                    group.addTask { [weak self] in
                        guard let self = self else { throw OrcaSwapError.unknown }
                        try Task.checkCancellation()
                        return (wallet.mintAddress, try await self.orcaSwap.getTradablePoolsPairs(
                            fromMint: wallet.mintAddress,
                            toMint: PublicKey.wrappedSOLMint.base58EncodedString
                        ))
                    }
                }
                for try await result in group {
                    await self.cache.save(pubkey: result.0, poolsPairs: result.1)
                }
            }
        }
    }

    func checkAccountValidation(account: String) -> Single<Bool> {
        Single.async { [weak self] in
            guard let self = self else { return false }
            return try await self.solanaAPIClient.checkAccountValidation(account: account)
        }
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
    ) -> Single<FeeAmount?> {
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
                return getFeeViaRelayMethod(
                    from: wallet,
                    receiver: receiver,
                    payingTokenMint: payingTokenMint
                )
            case .reward:
                return .just(.zero)
            }
        }
    }

    func getAvailableWalletsToPayFee(feeInSOL _: FeeAmount) -> Single<[Wallet]> {
        fatalError("Method has not been implemented")

        // Single.zip(
        //     walletsRepository.getWallets()
        //         .filter { ($0.lamports ?? 0) > 0 }
        //         .map { wallet -> Single<Wallet?> in
        //             if wallet.mintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
        //                 return (wallet.lamports ?? 0) >= feeInSOL.total ? .just(wallet) : .just(nil)
        //             }
        //             return relayService.calculateFeeInPayingToken(
        //                 feeInSOL: feeInSOL,
        //                 payingFeeTokenMint: wallet.mintAddress
        //             )
        //                 .map { ($0?.total ?? 0) <= (wallet.lamports ?? 0) }
        //                 .map { $0 ? wallet : nil }
        //                 .catchAndReturn(nil)
        //         }
        // )
        //     .map { $0.compactMap { $0 }}
    }

    func getFeesInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeWallet: Wallet
    ) -> Single<FeeAmount?> {
        guard relayMethod == .relay else { return .just(nil) }

        if payingFeeWallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
            return .just(feeInSOL)
        }

        return Single.async { [weak self] in
            guard let self = self else { throw Error.unknown }
            let tradableTopUpPoolsPair = try await self.orcaSwap.getTradablePoolsPairs(
                fromMint: payingFeeWallet.mintAddress,
                toMint: PublicKey.wrappedSOLMint.base58EncodedString
            )
            guard let topUpPools = try self.orcaSwap.findBestPoolsPairForEstimatedAmount(
                feeInSOL.total,
                from: tradableTopUpPoolsPair
            ) else {
                throw Error.swapPoolsNotFound
            }

            let transactionFee = topUpPools.getInputAmount(minimumAmountOut: feeInSOL.transaction, slippage: 0.01)
            let accountCreationFee = topUpPools.getInputAmount(
                minimumAmountOut: feeInSOL.accountBalances,
                slippage: 0.01
            )

            return .init(transaction: transactionFee ?? 0, accountBalances: accountCreationFee ?? 0)
        }
    }

    func getFreeTransactionFeeLimit() -> Single<UsageStatus> {
        fatalError("Method has not been implemented")
        // relayService.getFreeTransactionFeeLimit()
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
        guard let sender = wallet.pubkey else { return .error(Error.invalidSourceWallet) }
        // form request
        if receiver == sender {
            return .error(Error.sendToYourself)
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
}
