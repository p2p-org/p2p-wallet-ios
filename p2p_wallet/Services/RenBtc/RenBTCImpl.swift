//
// Created by Giang Long Tran on 07.02.2022.
//

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import RxSwift
import SolanaSwift

class RenBtcServiceImpl: RentBTC.Service {
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

    func hasAssociatedTokenAccountBeenCreated() -> Bool {
        walletRepository.getWallets().contains(where: \.token.isRenBTC)
    }

    func isAssociatedAccountCreatable() async throws -> Bool {
        let wallets = walletRepository
            .getWallets()
            .sorted { w1, w2 in (w1.lamports ?? 0) > (w2.lamports ?? 0) }

        // At lease one wallet is payable
        for wallet in wallets {
            let fee = try await getCreationFee(payingFeeMintAddress: wallet.mintAddress)
            if fee <= (wallet.lamports ?? 0) {
                return true
            }
        }

        return false
    }

    func createAccount(payingFeeAddress: String, payingFeeMintAddress: String) async throws -> SolanaSDK.TransactionID {
        guard let account = accountStorage.account else { throw SolanaSDK.Error.unauthorized }

        // Preparing
        let (accountCreationFee, lamportPerSignature, feePayerAccount, recentBlockHash) =
            try await(
                solanaSDK
                    .getMinimumBalanceForRentExemption(span: SolanaSDK.AccountInfo.span)
                    .value,
                solanaSDK.getLamportsPerSignature().value,
                feeRelayerApi.getFeePayerPubkey().value,
                solanaSDK.getRecentBlockhash().value
            )

        // Create raw transaction
        let preparedTransaction = try await solanaSDK.prepareTransaction(
            instructions: [
                try solanaSDK.createAssociatedTokenAccountInstruction(
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
            .value

        // Submit
        try await feeRelayer.load().value
        return try await feeRelayer
            .topUpAndRelayTransaction(
                preparedTransaction: preparedTransaction,
                payingFeeToken: .init(address: payingFeeAddress, mint: payingFeeMintAddress)
            )
            .map(\.first)
            .value!
    }

    func getCreationFee(payingFeeMintAddress: String) async throws -> SolanaSDK.Lamports {
        // Prepare
        _ = try await [orcaSwap.load().value, feeRelayer.load().value]

        let (accountCreationFee, transactionFee) = try await(
            solanaSDK
                .getMinimumBalanceForRentExemption(span: SolanaSDK.AccountInfo.span)
                .value,
            solanaSDK
                .getMinimumBalanceForRentExemption(span: SolanaSDK.AccountInfo.span)
                .value
        )

        let feeInSol = try await feeRelayer.calculateNeededTopUpAmount(
            expectedFee: .init(transaction: transactionFee, accountBalances: accountCreationFee),
            payingTokenMint: payingFeeMintAddress
        )
            .value

        let feeInPayingToken = try await feeRelayer.calculateFeeInPayingToken(
            feeInSOL: feeInSol,
            payingFeeTokenMint: payingFeeMintAddress
        )
            .value

        return feeInPayingToken?.total ?? .zero
    }
}
