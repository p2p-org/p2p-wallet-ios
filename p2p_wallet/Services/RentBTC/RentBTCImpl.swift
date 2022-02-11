//
// Created by Giang Long Tran on 07.02.2022.
//

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import RxSwift

class RentBtcServiceImpl: RentBTC.Service {
    private let solanaSDK: SolanaSDK
    private let feeRelayerApi: FeeRelayerAPIClientType
    private let accountStorage: AccountStorageType
    private let orcaSwap: OrcaSwapType
    private let walletRepository: WalletsRepository

    private var feeRelayer: FeeRelayer.Relay? = nil
    
    init(
        solanaSDK: SolanaSDK,
        feeRelayerApi: FeeRelayerAPIClientType,
        accountStorage: AccountStorageType,
        orcaSwap: OrcaSwapType,
        walletRepository: WalletsRepository
    ) {
        self.solanaSDK = solanaSDK
        self.feeRelayerApi = feeRelayerApi
        self.accountStorage = accountStorage
        self.orcaSwap = orcaSwap
        self.walletRepository = walletRepository
    }

    func load() -> Completable {
        do {
            feeRelayer = try FeeRelayer.Relay(
                apiClient: feeRelayerApi,
                solanaClient: solanaSDK,
                accountStorage: accountStorage,
                orcaSwapClient: orcaSwap
            )
        } catch {
            return .error(error)
        }
        return .empty()
    }

    func hasAssociatedTokenAccountBeenCreated() -> Single<Bool> {
        solanaSDK.hasAssociatedTokenAccountBeenCreated(tokenMint: .renBTCMint)
            .catch {error in
                if error.isEqualTo(SolanaSDK.Error.couldNotRetrieveAccountInfo) {
                    return .just(false)
                }
                throw error
            }
    }
    
    func isAssociatedAccountCreatable() -> Single<Bool> {
        .just(walletRepository.getWallets().filter { $0.amount > 0}.count > 0)
    }
    
    func createAssociatedTokenAccount(payingFeeAddress: String, payingFeeMintAddress: String) -> Single<SolanaSDK.TransactionID> {
        guard let account = accountStorage.account else { return .error(SolanaSDK.Error.unauthorized) }
        guard let feeRelayer = feeRelayer else {return .error(SolanaSDK.Error.other("Fee relay is not ready"))}
        
        return Single.zip(
            solanaSDK.getMinimumBalanceForRentExemption(span: 165),
            solanaSDK.getLamportsPerSignature(),
            solanaSDK.getRecentBlockhash(),
            feeRelayerApi.getFeePayerPubkey()
        ).flatMap { minimumBalanceForRentExemption, lamports, recentBlockHash,feePayer in
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

            return feeRelayer.topUpAndRelayTransaction(
                preparedTransaction: preparedTransaction,
                payingFeeToken: FeeRelayer.Relay.TokenInfo(
                    address: payingFeeAddress,
                    mint: payingFeeMintAddress
                )
            ).map { transactionIds in transactionIds.first ?? "" }
        }
    }

}
