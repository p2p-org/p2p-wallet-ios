//
//  RenBTCStatusService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import RxSwift
import SolanaSwift

class RenBTCStatusService: RenBTCStatusServiceType {
    @Injected private var solanaSDK: SolanaSDK
    @Injected private var feeRelayerAPIClient: FeeRelayerAPIClientType
    @Injected private var accountStorage: AccountStorageType
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var walletRepository: WalletsRepository
    @Injected private var feeRelayer: FeeRelayer.Relay

    private let locker = NSLock()
    private var minRenExemption: SolanaSDK.Lamports?
    private var lamportsPerSignature: SolanaSDK.Lamports?

    func load() -> Completable {
        Completable.zip(
            orcaSwap.load(),
            feeRelayer.load(),
            solanaSDK
                .getMinimumBalanceForRentExemption(span: SolanaSDK.AccountInfo.span)
                .do(onSuccess: { [weak self] in
                    self?.locker.lock()
                    self?.minRenExemption = $0
                    self?.locker.unlock()
                })
                .asCompletable(),
            solanaSDK
                .getLamportsPerSignature()
                .do(onSuccess: { [weak self] in
                    self?.locker.lock()
                    self?.lamportsPerSignature = $0
                    self?.locker.unlock()
                })
                .asCompletable()
        )
    }

    func hasRenBTCAccountBeenCreated() -> Bool {
        walletRepository.getWallets().contains(where: \.token.isRenBTC)
    }

    func getPayableWallets() -> Single<[Wallet]> {
        let wallets = walletRepository
            .getWallets()
            .filter { ($0.lamports ?? 0) > 0 }

        // At lease one wallet is payable
        return Single
            .zip(wallets.map { w -> Single<Wallet?> in
                getCreationFee(payingFeeMintAddress: w.mintAddress)
                    .map { $0 <= (w.lamports ?? 0) ? w : nil }
                    .catchAndReturn(nil)
            })
            .map { $0.compactMap { $0 } }
    }

    func createAccount(payingFeeAddress: String, payingFeeMintAddress: String) -> Single<SolanaSDK.TransactionID?> {
        guard let account = accountStorage.account else { return .error(SolanaSDK.Error.unauthorized) }

        return Single.zip(
            solanaSDK
                .getMinimumBalanceForRentExemption(span: SolanaSDK.AccountInfo.span),
            solanaSDK.getLamportsPerSignature(),
            feeRelayerAPIClient.getFeePayerPubkey(),
            solanaSDK.getRecentBlockhash()
        )
            .flatMap { [weak self] accountCreationFee, lamportPerSignature, feePayerAccount, recentBlockHash in
                guard let self = self else { return .error(SolanaSDK.Error.unknown) }
                return self.solanaSDK.prepareTransaction(
                    instructions: [
                        try self.solanaSDK.createAssociatedTokenAccountInstruction(
                            for: account.publicKey,
                            tokenMint: .renBTCMint,
                            payer: try SolanaSDK.PublicKey(string: feePayerAccount)
                        ),
                    ],
                    signers: [account],
                    feePayer: try SolanaSDK.PublicKey(string: feePayerAccount),
                    accountsCreationFee: accountCreationFee,
                    recentBlockhash: recentBlockHash,
                    lamportsPerSignature: lamportPerSignature
                )
                    .flatMap { [weak self] preparedTransaction in
                        guard let self = self else { return .error(SolanaSDK.Error.unknown) }
                        return self.feeRelayer
                            .topUpAndRelayTransaction(
                                preparedTransaction: preparedTransaction,
                                payingFeeToken: .init(address: payingFeeAddress, mint: payingFeeMintAddress)
                            )
                            .map(\.first)
                    }
            }
    }

    func getCreationFee(payingFeeMintAddress: String) -> Single<SolanaSDK.Lamports> {
        let feeAmount = SolanaSDK.FeeAmount(
            transaction: lamportsPerSignature ?? 5000,
            accountBalances: minRenExemption ?? 2_039_280
        )
        return feeRelayer.calculateNeededTopUpAmount(
            expectedFee: feeAmount,
            payingTokenMint: payingFeeMintAddress
        )
            .flatMap { [weak self] feeInSol -> Single<SolanaSDK.FeeAmount?> in
                guard let self = self else { throw SolanaSDK.Error.unknown }
                return self.feeRelayer.calculateFeeInPayingToken(
                    feeInSOL: feeInSol,
                    payingFeeTokenMint: payingFeeMintAddress
                )
            }
            .map {
                if let fees = $0?.total {
                    return fees
                }
                throw SolanaSDK.Error.other("Could not calculate fee")
            }
    }
}
