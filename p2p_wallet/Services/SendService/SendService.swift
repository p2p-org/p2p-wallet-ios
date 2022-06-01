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
    private let locker = NSLock()
    let relayMethod: SendTokenRelayMethod
    @Injected var solanaAPIClient: SolanaAPIClient
    @Injected private var orcaSwap: OrcaSwapType
    @Injected var feeRelayerAPIClient: FeeRelayerAPIClient
    @Injected var relayService: FeeRelayer
    @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
    @Injected private var feeService: FeeServiceType
    @Injected private var walletsRepository: WalletsRepository
    var cachedFeePayerPubkey: String?
    private var cachedPoolsSPLToSOL = [String: [PoolsPair]]()

    init(relayMethod: SendTokenRelayMethod) {
        self.relayMethod = relayMethod
    }

    // MARK: - Methods

    func load() -> Completable {
        fatalError("Method has not been implemented")

        // TODO: fix
        // var completables = [feeService.load()]
        //
        // if relayMethod == .relay {
        //     completables.append(
        //         orcaSwap.load()
        //             .andThen(relayService.load())
        //             .andThen(
        //                 // load all pools
        //                 Single.zip(
        //                     walletsRepository.getWallets()
        //                         .filter { ($0.lamports ?? 0) > 0 }
        //                         .map { wallet in
        //                             orcaSwap.getTradablePoolsPairs(
        //                                 fromMint: wallet.mintAddress,
        //                                 toMint: PublicKey.wrappedSOLMint.base58EncodedString
        //                             )
        //                                 .do(onSuccess: { [weak self] poolsPair in
        //                                     self?.locker.lock()
        //                                     self?.cachedPoolsSPLToSOL[wallet.mintAddress] = poolsPair
        //                                     self?.locker.unlock()
        //                                 })
        //                         }
        //                 )
        //                     .asCompletable()
        //             )
        //     )
        // }
        //
        // return .zip(completables)
    }

    func checkAccountValidation(account _: String) -> Single<Bool> {
        fatalError("Method has not been implemented")
        // solanaAPIClient.checkAccountValidation(account: account)
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
        //             if wallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
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
        feeInSOL _: FeeAmount,
        payingFeeWallet _: Wallet
    ) -> Single<FeeAmount?> {
        fatalError("Method has not been implemented")

        // guard relayMethod == .relay else { return .just(nil) }
        // if payingFeeWallet.mintAddress == PublicKey.wrappedSOLMint
        //     .base58EncodedString { return .just(feeInSOL) }
        // return relayService.calculateFeeInPayingToken(
        //     feeInSOL: feeInSOL,
        //     payingFeeTokenMint: payingFeeWallet.mintAddress
        // )
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
        guard let sender = wallet.pubkey else { return .error(SolanaError.other("Source wallet is not valid")) }
        // form request
        if receiver == sender {
            return .error(SolanaError.other(L10n.youCanNotSendTokensToYourself))
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
            request = Single.async { [weak self] in
                guard let self = self else { throw RenVMError.unknown }
                return try await self.renVMBurnAndReleaseService.burn(
                    recipient: receiver,
                    amount: amount
                )
            }
        }
        return request
    }
}
