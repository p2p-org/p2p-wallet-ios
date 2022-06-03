//
//  RenBTCStatusService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import FeeRelayerSwift
import Foundation
import OrcaSwapSwift
import Resolver
import RxConcurrency
import RxSwift
import SolanaSwift

class RenBTCStatusService: RenBTCStatusServiceType {
    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var blockchainClient: SolanaBlockchainClient
    @Injected private var feeRelayerContextManager: FeeRelayerContextManager
    @Injected private var feeRelayerAPIClient: FeeRelayerAPIClient
    @Injected private var accountStorage: AccountStorageType
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var feeRelayer: FeeRelayer

    private var minRenExemption: Lamports?
    private var lamportsPerSignature: Lamports?

    func load() async throws {
        try await orcaSwap.load()

        minRenExemption = try await solanaAPIClient
            .getMinimumBalanceForRentExemption(span: AccountInfo.BUFFER_LENGTH)
        lamportsPerSignature = try await solanaAPIClient.getLamportsPerSignature()
    }

    func hasRenBTCAccountBeenCreated() -> Bool {
        walletsRepository.getWallets().contains(where: \.token.isRenBTC)
    }

    func getPayableWallets() async throws -> [Wallet] {
        let wallets = walletsRepository
            .getWallets()
            .filter { ($0.lamports ?? 0) > 0 }

        // At lease one wallet is payable
        return await withTaskGroup(of: (Wallet, Lamports?).self) { group -> [Wallet] in
            for w in wallets {
                group.addTask { [weak self] in
                    (w, try? await self?.getCreationFee(payingFeeMintAddress: w.mintAddress))
                }
            }

            var wallets = [Wallet]()
            for await result in group where result.1 != nil && result.1! <= (result.0.lamports ?? 0) {
                wallets.append(result.0)
            }
            return wallets
        }
    }

    func createAccount(payingFeeAddress address: String, payingFeeMintAddress mint: String) async throws {
        guard let address = try? PublicKey(string: address),
              let mint = try? PublicKey(string: mint) else { throw SolanaError.unknown }
        guard let account = accountStorage.account else { throw SolanaError.unauthorized }

        // prepare transaction
        async let preparing = blockchainClient.prepareTransaction(
            instructions: [
                AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                    mint: .renBTCMint,
                    owner: account.publicKey,
                    payer: account.publicKey
                ),
            ],
            signers: [account],
            feePayer: account.publicKey,
            feeCalculator: nil
        )

        async let updating: () = feeRelayerContextManager.update()

        let (preparedTransaction, _) = try await(preparing, updating)

        let context = try await feeRelayerContextManager.getCurrentContext()
        let tx = try await feeRelayer.topUpAndRelayTransaction(
            context,
            preparedTransaction,
            fee: .init(address: address, mint: mint),
            config: .init(
                operationType: .transfer,
                currency: mint.base58EncodedString
            )
        )

        try await solanaAPIClient.waitForConfirmation(signature: tx, ignoreStatus: true)

        walletsRepository.batchUpdate { wallets in
            guard let string = wallets.first(where: { $0.isNativeSOL })?.pubkey,
                  let nativeWalletAddress = try? PublicKey(string: string),
                  let renBTCAddress = try? PublicKey.associatedTokenAddress(
                      walletAddress: nativeWalletAddress,
                      tokenMintAddress: .renBTCMint
                  )
            else { return wallets }

            var wallets = wallets

            if !wallets.contains(where: { $0.pubkey == renBTCAddress.base58EncodedString }) {
                wallets.append(
                    .init(
                        pubkey: renBTCAddress.base58EncodedString,
                        lamports: 0,
                        token: .renBTC
                    )
                )
            }

            return wallets
        }
    }

    func getCreationFee(payingFeeMintAddress mintAddress: String) async throws -> Lamports {
        let mintAddress = try PublicKey(string: mintAddress)

        let feeAmount = FeeAmount(
            transaction: lamportsPerSignature ?? 5000,
            accountBalances: minRenExemption ?? 2_039_280
        )

        let feeInSOL = try await feeRelayer.feeCalculator.calculateNeededTopUpAmount(
            try await feeRelayerContextManager.getCurrentContext(),
            expectedFee: feeAmount,
            payingTokenMint: mintAddress
        )

        let feeInToken = try await feeRelayer.feeCalculator.calculateFeeInPayingToken(
            orcaSwap: orcaSwap,
            feeInSOL: feeInSOL,
            payingFeeTokenMint: mintAddress
        )

        guard let fees = feeInToken?.total else {
            throw SolanaError.other("Could not calculating fees")
        }

        return fees
    }
}
