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
import SolanaSwift

class SendService: SendServiceType {
    let relayMethod: SendTokenRelayMethod

    @Injected var accountStorage: SolanaAccountStorage
    @Injected var solanaAPIClient: SolanaAPIClient
    @Injected var blockchainClient: BlockchainClient
    @Injected var orcaSwap: OrcaSwapType
    @Injected var feeRelayer: FeeRelayer
    @Injected var feeRelayerAPIClient: FeeRelayerAPIClient
    @Injected var contextManager: FeeRelayerContextManager

    @Injected private var renVMBurnAndReleaseService: BurnAndReleaseService
    @Injected private var walletsRepository: WalletsRepository

    init(relayMethod: SendTokenRelayMethod) {
        self.relayMethod = relayMethod
    }

    // MARK: - Methods

    func load() async throws {
        _ = try await(
            orcaSwap.load(),
            contextManager.update()
        )
    }

    func checkAccountValidation(account: String) async throws -> Bool {
        try await solanaAPIClient.checkAccountValidation(account: account)
    }

    func isTestNet() -> Bool {
        solanaAPIClient.endpoint.network.isTestnet
    }

    // MARK: - Fees calculator

    func getFees(
        from wallet: Wallet,
        receiver: String?,
        network: SendNetwork,
        payingTokenMint: String?
    ) async throws -> FeeAmount? {
        switch network {
        case .bitcoin:
            let burnFee = try await solanaAPIClient.getMinimumBalanceForRentExemption(span: 97) + 5000
            
            let exchangeRate = try await feeRelayerAPIClient.feeTokenData(mint: Token.renBTC.address).exchangeRate
            let compensationAmountDouble = (Double(burnFee) * exchangeRate / pow(Double(10), Double(Token.nativeSolana.decimals-Token.renBTC.decimals)))
            let feeInRenBTC = UInt64(compensationAmountDouble.rounded(.up)).convertToBalance(decimals: Token.renBTC.decimals)
            
            return FeeAmount(
                transaction: 0,
                accountBalances: 0,
                others: [
                    .init(amount: feeInRenBTC, unit: "renBTC"),
                ]
            )
        case .solana:
            guard let receiver = receiver else {
                return nil
            }

            switch relayMethod {
            case .relay:
                return try await getFeeViaRelayMethod(
                    try await contextManager.getCurrentContext(),
                    from: wallet,
                    receiver: receiver,
                    payingTokenMint: payingTokenMint
                )
            case .reward:
                return FeeAmount.zero
            }
        }
    }

    func getAvailableWalletsToPayFee(feeInSOL: FeeAmount) async throws -> [Wallet] {
        let wallets = walletsRepository.getWallets()
            .filter { ($0.lamports ?? 0) > 0 }

        return try await withThrowingTaskGroup(of: Wallet?.self) { group in
            var result = [Wallet]()

            for wallet in wallets {
                // Solana wallet
                if wallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString,
                   (wallet.lamports ?? 0) >= feeInSOL.total
                {
                    result.append(wallet)
                }

                // Other
                group.addTask(priority: .userInitiated) { [weak self] in
                    guard let self = self else { return nil }
                    let fee = try? await self.feeRelayer.feeCalculator.calculateFeeInPayingToken(
                        orcaSwap: self.orcaSwap,
                        feeInSOL: feeInSOL,
                        payingFeeTokenMint: try PublicKey(string: wallet.mintAddress)
                    )

                    return (fee?.total ?? 0) <= (wallet.lamports ?? 0) ? wallet : nil
                }
            }

            for try await wallet in group where wallet != nil {
                result.append(wallet!)
            }

            return result
        }
    }

    func getFeesInPayingToken(
        feeInSOL: FeeAmount,
        payingFeeWallet: Wallet
    ) async throws -> FeeAmount? {
        guard relayMethod == .relay else { return nil }

        if payingFeeWallet.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
            return feeInSOL
        }

        return try await feeRelayer.feeCalculator.calculateFeeInPayingToken(
            orcaSwap: orcaSwap,
            feeInSOL: feeInSOL,
            payingFeeTokenMint: try PublicKey(string: payingFeeWallet.mintAddress)
        )
    }

    func getFreeTransactionFeeLimit() async throws -> UsageStatus {
        try await contextManager.getCurrentContext().usageStatus
    }

    // MARK: - Send method

    func send(
        from wallet: Wallet,
        receiver: String,
        amount: Double,
        network: SendNetwork,
        payingFeeWallet: Wallet? // nil for relayMethod == .reward
    ) async throws -> String {
        try await contextManager.update()

        let amount = amount.toLamport(decimals: wallet.token.decimals)
        guard let sender = wallet.pubkey else { throw Error.invalidSourceWallet }
        // form request
        if receiver == sender {
            throw Error.sendToYourself
        }

        // detect network
        switch network {
        case .solana:
            switch relayMethod {
            case .relay:
                return try await sendToSolanaBCViaRelayMethod(
                    try await contextManager.getCurrentContext(),
                    from: wallet,
                    receiver: receiver,
                    amount: amount,
                    payingFeeWallet: payingFeeWallet
                )
            case .reward:
                return try await sendToSolanaBCViaRewardMethod(
                    try await contextManager.getCurrentContext(),
                    from: wallet,
                    receiver: receiver,
                    amount: amount
                )
            }
        case .bitcoin:
            // FIXME: temporary solution
            
            let renBTCAddress = try PublicKey.associatedTokenAddress(
                walletAddress: accountStorage.account!.publicKey,
                tokenMintAddress: try PublicKey(string: Token.renBTC.address)
            )
            
            let preRenBTCBalance = try await solanaAPIClient.getTokenAccountBalance(pubkey: renBTCAddress.base58EncodedString, commitment: nil)
                .amountInUInt64
            
            // Swap renBTC to Solana to pay fee
            let transactionFee: UInt64 = 5000
            let burnFee = try await solanaAPIClient.getMinimumBalanceForRentExemption(span: 97) + transactionFee
            
            let exchangeRate = try await feeRelayerAPIClient.feeTokenData(mint: Token.renBTC.address).exchangeRate
            let compensationAmountDouble = (Double(burnFee) * exchangeRate / pow(Double(10), Double(Token.nativeSolana.decimals-Token.renBTC.decimals)))
            let compensationAmount = UInt64(compensationAmountDouble.rounded(.up))
            
            let swapTxId = try await swapRenBTCToSolanaToPayFee(
                burnFee: burnFee,
                burnFeeInRenBTC: compensationAmount
            )
            
            // wait for confirmation
            try await solanaAPIClient.waitForConfirmation(signature: swapTxId, ignoreStatus: true)
            
            // fix amount
            
            var amount = amount
            if let preRenBTCBalance = preRenBTCBalance,
               amount + compensationAmount > preRenBTCBalance
            {
                guard preRenBTCBalance > compensationAmount else {
                    throw RenVMError("Amount is too small")
                }
                amount = preRenBTCBalance - compensationAmount
            }
            
            return try await renVMBurnAndReleaseService.burnAndRelease(
                recipient: receiver,
                amount: amount,
                waitForReleasing: false
            )
        }
    }
    
    private func swapRenBTCToSolanaToPayFee(
        burnFee: UInt64,
        burnFeeInRenBTC: UInt64
    ) async throws -> String {
        let context = try await contextManager.getCurrentContext()
        
        let renBTCMint = try PublicKey(string: Token.renBTC.address)
        
        class FreeFeeCalculator: FeeCalculator {
            func calculateNetworkFee(transaction: Transaction) throws -> FeeAmount {
                .zero
            }
        }
        
        let swapPreparedTransaction = try await blockchainClient.prepareTransaction(
            instructions: [
                SystemProgram.transferInstruction(
                    from: context.feePayerAddress,
                    to: accountStorage.account!.publicKey,
                    lamports: burnFee
                ),
                TokenProgram.transferInstruction(
                    source: try PublicKey.associatedTokenAddress(walletAddress: accountStorage.account!.publicKey, tokenMintAddress: renBTCMint),
                    destination: try PublicKey.associatedTokenAddress(walletAddress: context.feePayerAddress, tokenMintAddress: renBTCMint),
                    owner: accountStorage.account!.publicKey,
                    amount: burnFeeInRenBTC
                )
            ],
            signers: [accountStorage.account!],
            feePayer: context.feePayerAddress,
            feeCalculator: FreeFeeCalculator()
        )
        
        // send swap transaction
        
        return try await feeRelayer.topUpAndRelayTransaction(
            context,
            swapPreparedTransaction,
            fee: nil,
            config: .init(
                operationType: .transfer,
                currency: PublicKey.renBTCMint.base58EncodedString
            )
        )
    }
}
