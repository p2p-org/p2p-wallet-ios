//
// Created by Giang Long Tran on 07.02.2022.
//

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import RxSwift
import SolanaSwift

class RentBtcServiceImpl: RentBTC.Service {
    private let solanaSDK: SolanaSDK
    private let feeRelayerApi: FeeRelayerAPIClientType
    private let accountStorage: AccountStorageType
    private let orcaSwap: OrcaSwapType
    private let walletRepository: WalletsRepository
    private var feeRelayer: FeeRelayer.Relay

    init(
        solanaSDK: SolanaSDK,
        feeRelayerApi: FeeRelayerAPIClientType,
        accountStorage: AccountStorageType,
        orcaSwap: OrcaSwapType,
        walletRepository: WalletsRepository
    ) throws {
        self.solanaSDK = solanaSDK
        self.feeRelayerApi = feeRelayerApi
        self.accountStorage = accountStorage
        self.orcaSwap = orcaSwap
        self.walletRepository = walletRepository

        feeRelayer = try FeeRelayer.Relay(
            apiClient: feeRelayerApi,
            solanaClient: solanaSDK,
            accountStorage: accountStorage,
            orcaSwapClient: orcaSwap
        )
    }

    func hasAssociatedTokenAccountBeenCreated() -> Single<Bool> {
        solanaSDK.hasAssociatedTokenAccountBeenCreated(tokenMint: .renBTCMint)
            .catch { error in
                if error.isEqualTo(SolanaSDK.Error.couldNotRetrieveAccountInfo) {
                    return .just(false)
                }
                throw error
            }
    }

    func isAssociatedAccountCreatable() -> Single<Bool> {
        .just(walletRepository.getWallets().filter { $0.amount > 0 }.count > 0)
    }

    func createAssociatedTokenAccount(payingFeeAddress: String, payingFeeMintAddress: String) -> Single<SolanaSDK.TransactionID> {
        if payingFeeMintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
            return createAssociatedTokenAccount()
        } else {
            return createAssociatedTokenAccountWithRelay(
                payingFeeAddress: payingFeeAddress,
                payingFeeMintAddress: payingFeeMintAddress
            )
        }
    }

    private func createAssociatedTokenAccount() -> Single<SolanaSDK.TransactionID> {
        do {
            return solanaSDK.createAssociatedTokenAccount(tokenMint: .renBTCMint, isSimulation: false)
        } catch {
            return .error(error)
        }
    }

    private func createAssociatedTokenAccountWithRelay(payingFeeAddress: String, payingFeeMintAddress: String) -> Single<SolanaSDK.TransactionID> {
        guard let account = accountStorage.account else { return .error(SolanaSDK.Error.unauthorized) }

        return Single.zip(
            solanaSDK.getMinimumBalanceForRentExemption(span: 165),
            solanaSDK.getLamportsPerSignature(),
            solanaSDK.getRecentBlockhash(),
            feeRelayerApi.getFeePayerPubkey()
        ).flatMap { minimumBalanceForRentExemption, lamports, recentBlockHash, feePayer in
            var transaction = SolanaSDK.Transaction()
            transaction.instructions.append(
                try self.solanaSDK.createAssociatedTokenAccountInstruction(
                    for: account.publicKey,
                    tokenMint: .renBTCMint,
                    payer: try SolanaSDK.PublicKey(string: feePayer)
                )
            )
            transaction.feePayer = try SolanaSDK.PublicKey(string: feePayer)
            transaction.recentBlockhash = recentBlockHash

            let transactionFee = try transaction.calculateTransactionFee(lamportsPerSignatures: lamports)
            let accountCreationFee = minimumBalanceForRentExemption

            let expectedFee = SolanaSDK.FeeAmount(
                transaction: transactionFee,
                accountBalances: accountCreationFee
            )

            let preparedTransaction = SolanaSDK.PreparedTransaction(
                transaction: transaction,
                signers: [account],
                expectedFee: expectedFee
            )

            return self.feeRelayer
                .load()
                .andThen(
                    self.feeRelayer.topUpAndRelayTransaction(
                        preparedTransaction: preparedTransaction,
                        payingFeeToken: FeeRelayer.Relay.TokenInfo(
                            address: payingFeeAddress,
                            mint: payingFeeMintAddress
                        )
                    )
                ).map { transactionIds in transactionIds.first ?? "" }
        }
    }

    func getCreationFee(payingFeeAddress: String, payingFeeMintAddress: String) -> Single<SolanaSDK.Lamports> {
        Completable.zip(
            orcaSwap.load(),
            feeRelayer.load()
        ).andThen(
            Single.zip(
                solanaSDK.getMinimumBalanceForRentExemption(span: 165),
                solanaSDK.getLamportsPerSignature()
            ).flatMap { [weak self] minimumBalance, lamportPerSignature -> Single<SolanaSDK.Lamports> in
                guard let self = self else { return .error(SolanaSDK.Error.unknown) }

                if payingFeeMintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
                    // Create fake transaction
                    var transaction = SolanaSDK.Transaction()
                    transaction.instructions.append(
                        try self.solanaSDK.createAssociatedTokenAccountInstruction(
                            for: SolanaSDK.PublicKey.fake,
                            tokenMint: .renBTCMint,
                            payer: SolanaSDK.PublicKey.fake
                        )
                    )
                    transaction.feePayer = SolanaSDK.PublicKey.fake
                    transaction.recentBlockhash = ""

                    let transactionFee = try transaction.calculateTransactionFee(lamportsPerSignatures: lamportPerSignature)
                    let accountCreationFee = minimumBalance

                    let feeAmount = transactionFee + accountCreationFee

                    return .just(feeAmount)
                } else {
                    var transaction = SolanaSDK.Transaction()
                    transaction.instructions.append(
                        try self.solanaSDK.createAssociatedTokenAccountInstruction(
                            for: SolanaSDK.PublicKey.fake,
                            tokenMint: .renBTCMint,
                            payer: SolanaSDK.PublicKey.fake
                        )
                    )
                    transaction.feePayer = SolanaSDK.PublicKey.fake
                    transaction.recentBlockhash = ""

                    let transactionFee = try transaction.calculateTransactionFee(lamportsPerSignatures: lamportPerSignature)
                    let accountCreationFee = minimumBalance

                    let expectedFee = SolanaSDK.FeeAmount(
                        transaction: transactionFee,
                        accountBalances: accountCreationFee
                    )

                    let feeAmount = self.feeRelayer.calculateFee(preparedTransaction: .init(transaction: transaction, signers: [], expectedFee: expectedFee))
                    return self.orcaSwap.getTradablePoolsPairs(
                        fromMint: SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString,
                        toMint: payingFeeMintAddress
                    ).map { pairs -> SolanaSDK.Lamports in
                        let pair = try self.orcaSwap.findBestPoolsPairForInputAmount(feeAmount.total, from: pairs)
                        return pair?.getOutputAmount(fromInputAmount: feeAmount.total) ?? 0
                    }
                }
            }
        )
    }
}
