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

    private var feeRelayer: FeeRelayer.Relay? = nil

    init(
        solanaSDK: SolanaSDK,
        feeRelayerApi: FeeRelayerAPIClientType,
        accountStorage: AccountStorageType,
        orcaSwap: OrcaSwapType
    ) {
        self.solanaSDK = solanaSDK
        self.feeRelayerApi = feeRelayerApi
        self.accountStorage = accountStorage
        self.orcaSwap = orcaSwap
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
    }

    func createAssociatedTokenAccount(payingFeeAddress: String, payingFeeMintAddress: String) -> Single<SolanaSDK.TransactionID> {
        guard let account = accountStorage.account else { return .error(SolanaSDK.Error.unauthorized) }
        
        return Single.zip(
            solanaSDK.getMinimumBalanceForRentExemption(span: 165),
            solanaSDK.getLamportsPerSignature(),
            feeRelayerApi.getFeePayerPubkey()
        ).flatMap { minimumBalanceForRentExemption, lamports, payer in
            var transaction = SolanaSDK.Transaction()
            transaction.instructions.append(
                try solanaSDK.createAssociatedTokenAccountInstruction(
                    for: account.publicKey,
                    tokenMint: .renBTCMint,
                    payer: try SolanaSDK.PublicKey(string: payer)
                )
            )

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

            feeRelayer?.topUpAndRelayTransaction(
                preparedTransaction: preparedTransaction,
                payingFeeToken: FeeRelayer.Relay.TokenInfo(
                    address: payingFeeAddress,
                    mint: payingFeeMintAddress
                )
            )
        }
    }

}
