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
        let wallets = walletRepository.getWallets()

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
        if payingFeeMintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
            return try await createAccountUsingSolToken()
        } else {
            return try await createAccountUsingSplToken(
                payingFeeAddress: payingFeeAddress,
                payingFeeMintAddress: payingFeeMintAddress
            )
        }
    }

    private func createAccountUsingSolToken() async throws -> SolanaSDK.TransactionID {
        try await solanaSDK.createAssociatedTokenAccount(tokenMint: .renBTCMint, isSimulation: false).value
    }

    private func createAccountUsingSplToken(
        payingFeeAddress: String,
        payingFeeMintAddress: String
    ) async throws -> SolanaSDK.TransactionID {
        guard let account = accountStorage.account else { throw SolanaSDK.Error.unauthorized }

        // Preparing
        let accountCreationFee: UInt64 = try await solanaSDK
            .getMinimumBalanceForRentExemption(span: SolanaSDK.AccountInfo.span)
            .value

        let lamportPerSignature: UInt64 = try await solanaSDK.getLamportsPerSignature().value
        let feePayerAccount: String = try await feeRelayerApi.getFeePayerPubkey().value
        let recentBlockHash: String = try await solanaSDK.getRecentBlockhash().value

        // Create raw transaction
        var transaction = SolanaSDK.Transaction()
        transaction.instructions.append(
            try solanaSDK.createAssociatedTokenAccountInstruction(
                for: account.publicKey,
                tokenMint: .renBTCMint,
                payer: try SolanaSDK.PublicKey(string: feePayerAccount)
            )
        )
        transaction.feePayer = try SolanaSDK.PublicKey(string: feePayerAccount)
        transaction.recentBlockhash = recentBlockHash

        // Calculate expected transaction fee
        let expectedFee: SolanaSDK.FeeAmount = try await feeRelayer.calculateNeededTopUpAmount(
            expectedFee: .init(transaction: lamportPerSignature * 1, accountBalances: accountCreationFee),
            payingTokenMint: payingFeeMintAddress
        ).value

        // Prepare transaction
        let preparedTransaction = SolanaSDK.PreparedTransaction(
            transaction: transaction,
            signers: [account],
            expectedFee: expectedFee
        )

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
        try await orcaSwap.load().value
        try await feeRelayer.load().value

        // Calculate account creation fee
        let accountCreationFee: UInt64 = try await solanaSDK
            .getMinimumBalanceForRentExemption(span: SolanaSDK.AccountInfo.span)
            .value

        // Calculate transaction fee
        let transactionFee: UInt64 = try await solanaSDK.getLamportsPerSignature().value * 1

        // Convert fee amount to spl amount

        // SOL case
        if payingFeeMintAddress == SolanaSDK.PublicKey.wrappedSOLMint.base58EncodedString {
            return accountCreationFee + transactionFee
        }

        // SPL case
        let feeInSplToken: SolanaSDK.FeeAmount = try await feeRelayer.calculateNeededTopUpAmount(
            expectedFee: .init(transaction: transactionFee, accountBalances: accountCreationFee),
            payingTokenMint: payingFeeMintAddress
        ).value

        return feeInSplToken.total
    }
}
