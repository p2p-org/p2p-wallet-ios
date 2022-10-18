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
    private var rentExemptMinimum: Lamports?

    private var renBTCMint: PublicKey {
        Defaults.apiEndPoint.network == .mainnetBeta ? .renBTCMint : .renBTCMintDevnet
    }

    func load() async throws {
        try await orcaSwap.load()

        minRenExemption = try await solanaAPIClient
            .getMinimumBalanceForRentExemption(span: AccountInfo.BUFFER_LENGTH)
        lamportsPerSignature = try await solanaAPIClient.getLamportsPerSignature()
        rentExemptMinimum = try await solanaAPIClient.getMinimumBalanceForRentExemption(span: 0)
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
            for await(w, fee) in group where fee != nil && fee! <= (w.lamports ?? 0) {
                // special case where wallet is native sol, needs to keeps rentExemptMinimum lamports in account to prevent error
                // Transaction leaves an account with a lower balance than rent-exempt minimum
                if w.isNativeSOL, (w.lamports ?? 0) - fee! < (rentExemptMinimum ?? 0) {
                    continue
                } else {
                    wallets.append(w)
                }
            }
            return wallets
        }
    }

    func createAccount(payingFeeAddress address: String?, payingFeeMintAddress mint: String?) async throws {
        guard let account = accountStorage.account else { throw SolanaError.unauthorized }

        let feeCalculator: FeeCalculator?
        let payingFeeToken: FeeRelayerSwift.TokenAccount?
        let signers: [Account]

        // CASE 1: User is paying for renBTC creation
        if let address = address,
           let mint = mint
        {
            feeCalculator = nil // use default solana's feeCalculator
            payingFeeToken = .init(
                address: try PublicKey(string: address),
                mint: try PublicKey(string: mint)
            )
            signers = [account]
        }

        // CASE 2: Free renBTC creation
        else {
            class RenBTCFreeFeeCalculator: FeeCalculator {
                func calculateNetworkFee(transaction _: SolanaSwift.Transaction) throws -> SolanaSwift.FeeAmount {
                    .zero
                }
            }
            feeCalculator = RenBTCFreeFeeCalculator()
            payingFeeToken = nil
            signers = []
        }

        // preparing process
        let feePayer = try await feeRelayerContextManager.getCurrentContext().feePayerAddress
        async let preparing = blockchainClient.prepareTransaction(
            instructions: [
                AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                    mint: renBTCMint,
                    owner: account.publicKey,
                    payer: feePayer
                ),
            ],
            signers: signers,
            feePayer: feePayer,
            feeCalculator: feeCalculator
        )

        // updating process
        async let updating: () = feeRelayerContextManager.update()

        // run concurrently
        let (preparedTransaction, _) = try await(preparing, updating)

        // get context
        let context = try await feeRelayerContextManager.getCurrentContext()

        // relay transaction
        let tx = try await feeRelayer.topUpAndRelayTransaction(
            context,
            preparedTransaction,
            fee: payingFeeToken,
            config: .init(
                operationType: .transfer,
                currency: mint ?? renBTCMint.base58EncodedString
            )
        )

//        try await solanaAPIClient.waitForConfirmation(signature: tx, ignoreStatus: true)

        walletsRepository.batchUpdate { wallets in
            guard let string = wallets.first(where: { $0.isNativeSOL })?.pubkey,
                  let nativeWalletAddress = try? PublicKey(string: string),
                  let renBTCAddress = try? PublicKey.associatedTokenAddress(
                      walletAddress: nativeWalletAddress,
                      tokenMintAddress: renBTCMint
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
