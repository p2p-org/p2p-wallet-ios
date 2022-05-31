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
    @Injected private var feeRelayerAPIClient: FeeRelayerAPIClient
    @Injected private var accountStorage: AccountStorageType
    @Injected private var orcaSwap: OrcaSwapType
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var feeRelayer: FeeRelayer

    private var minRenExemption: SolanaSDK.Lamports?
    private var lamportsPerSignature: SolanaSDK.Lamports?

    func load() -> Completable {
        Completable.async {
            try await self.orcaSwap.load()

            self.minRenExemption = try await self.solanaAPIClient
                .getMinimumBalanceForRentExemption(span: AccountInfo.BUFFER_LENGTH)
            self.lamportsPerSignature = try await self.solanaAPIClient.getFees(commitment: nil).feeCalculator?
                .lamportsPerSignature
        }
    }

    func hasRenBTCAccountBeenCreated() -> Bool {
        walletsRepository.getWallets().contains(where: \.token.isRenBTC)
    }

    func getPayableWallets() -> Single<[Wallet]> {
        let wallets = walletsRepository
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

    func createAccount(payingFeeAddress _: String, payingFeeMintAddress _: String) -> Completable {
        fatalError("Method has not been implemented")

        // guard let account = accountStorage.account else { return .error(SolanaSDK.Error.unauthorized) }
        //
        // return Single.zip(
        //     solanaSDK
        //         .getMinimumBalanceForRentExemption(span: SolanaSDK.AccountInfo.span),
        //     solanaSDK.getLamportsPerSignature(),
        //     feeRelayerAPIClient.getFeePayerPubkey(),
        //     solanaSDK.getRecentBlockhash()
        // )
        //     .flatMap { [weak self] accountCreationFee, lamportPerSignature, feePayerAccount, recentBlockHash -> Single<String?> in
        //         guard let self = self else { return .error(SolanaSDK.Error.unknown) }
        //         return self.solanaSDK.prepareTransaction(
        //             instructions: [
        //                 try self.solanaSDK.createAssociatedTokenAccountInstruction(
        //                     for: account.publicKey,
        //                     tokenMint: .renBTCMint,
        //                     payer: try SolanaSDK.PublicKey(string: feePayerAccount)
        //                 ),
        //             ],
        //             signers: [account],
        //             feePayer: try SolanaSDK.PublicKey(string: feePayerAccount),
        //             accountsCreationFee: accountCreationFee,
        //             recentBlockhash: recentBlockHash,
        //             lamportsPerSignature: lamportPerSignature
        //         )
        //             .flatMap { [weak self] preparedTransaction in
        //                 guard let self = self else { return .error(SolanaSDK.Error.unknown) }
        //                 return self.feeRelayer
        //                     .topUpAndRelayTransaction(
        //                         preparedTransaction: preparedTransaction,
        //                         payingFeeToken: .init(
        //                             address: payingFeeAddress,
        //                             mint: payingFeeMintAddress
        //                         ),
        //                         operationType: .other,
        //                         currency: SolanaSDK.PublicKey.renBTCMint.base58EncodedString
        //                     )
        //                     .map(\.first)
        //             }
        //     }
        //     .flatMapCompletable { [weak self] in
        //         guard let self = self else { throw SolanaSDK.Error.unknown }
        //         guard let signature = $0 else { throw SolanaSDK.Error.other("Could not get transaction id") }
        //         return self.solanaSDK.waitForConfirmation(signature: signature)
        //     }
        //     .do(onCompleted: { [weak self] in
        //         DispatchQueue.main.async { [weak self] in
        //             guard let self = self else { return }
        //             self.walletsRepository.batchUpdate { wallets in
        //                 guard let string = wallets.first(where: { $0.isNativeSOL })?.pubkey,
        //                       let nativeWalletAddress = try? SolanaSDK.PublicKey(string: string),
        //                       let renBTCAddress = try? SolanaSDK.PublicKey.associatedTokenAddress(
        //                           walletAddress: nativeWalletAddress,
        //                           tokenMintAddress: .renBTCMint
        //                       )
        //                 else { return wallets }
        //
        //                 var wallets = wallets
        //
        //                 if !wallets.contains(where: { $0.pubkey == renBTCAddress.base58EncodedString }) {
        //                     wallets.append(
        //                         .init(
        //                             pubkey: renBTCAddress.base58EncodedString,
        //                             lamports: 0,
        //                             token: .renBTC
        //                         )
        //                     )
        //                 }
        //
        //                 return wallets
        //             }
        //         }
        //     })
    }

    func getCreationFee(payingFeeMintAddress _: String) -> Single<SolanaSDK.Lamports> {
        fatalError("Method has not been implemented")

        // let feeAmount = SolanaSDK.FeeAmount(
        //     transaction: lamportsPerSignature ?? 5000,
        //     accountBalances: minRenExemption ?? 2_039_280
        // )
        // return feeRelayer.calculateNeededTopUpAmount(
        //     expectedFee: feeAmount,
        //     payingTokenMint: payingFeeMintAddress
        // )
        //     .flatMap { [weak self] feeInSol -> Single<SolanaSDK.FeeAmount?> in
        //         guard let self = self else { throw SolanaSDK.Error.unknown }
        //         return self.feeRelayer.calculateFeeInPayingToken(
        //             feeInSOL: feeInSol,
        //             payingFeeTokenMint: payingFeeMintAddress
        //         )
        //     }
        //     .map {
        //         if let fees = $0?.total {
        //             return fees
        //         }
        //         throw SolanaSDK.Error.other("Could not calculate fee")
        //     }
    }
}
