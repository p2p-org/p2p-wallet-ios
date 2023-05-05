// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A strategy for orca swap transactions.
public class P2POrcaSwapWrapperParseStrategy: TransactionParseStrategy {
    /// The list of orca program signatures that will be parsed by this strategy
    private static let orcaProgramSignatures = [
        "12YKFL4mnZz6CBEGePrf293mEzueQM3h8VLPUJsKpGs9",
    ]

    private let apiClient: SolanaAPIClient
    private let tokensRepository: SolanaTokensRepository

    init(apiClient: SolanaAPIClient, tokensRepository: SolanaTokensRepository) {
        self.apiClient = apiClient
        self.tokensRepository = tokensRepository
    }

    open func isHandlable(with transactionInfo: TransactionInfo) -> Bool {
        transactionInfo.transaction.message.instructions.contains {
            Self.orcaProgramSignatures.contains($0.programId)
        }
    }

    open func parse(
        _ transactionInfo: TransactionInfo,
        config configuration: Configuration
    ) async throws -> AnyHashable? {
        try await _parse(
            transactionInfo: transactionInfo,
            config: configuration
        )
    }

    func _parse(
        transactionInfo: TransactionInfo,
        config: Configuration
    ) async throws -> AnyHashable? {
        try Task.checkCancellation()

        // Find P2P swap instruction
        let swapInstructionIndex = transactionInfo.transaction.message.instructions
            .lastIndex { (i: ParsedInstruction) in
                if Self.orcaProgramSignatures.contains(where: { $0 == i.programId }) {
                    if let iData = i.data, Base58.decode(iData).first == 4 { return true }
                }
                return false
            }
        guard let swapInstructionIndex = swapInstructionIndex else { return nil }

        // First attempt of extraction
        let swapInstruction = transactionInfo.transaction.message.instructions[swapInstructionIndex]
        guard
            var sourceAddress: String = swapInstruction.accounts?[3],
            var (sourceWallet, sourceChange) = try await parseToken(transactionInfo, for: sourceAddress),
            var destinationAddress: String = swapInstruction.accounts?[5],
            var (destinationWallet, destinationChange) = try await parseToken(transactionInfo, for: destinationAddress)
        else { return nil }

        let totalInstructions = transactionInfo.transaction.message.instructions.count
        
        // Swap from native SOL
        if sourceChange == .zero, swapInstructionIndex + 1 < totalInstructions {
            let closeInstruction = transactionInfo.transaction.message.instructions[swapInstructionIndex + 1]
            if closeInstruction.programId == TokenProgram.id.base58EncodedString {
                if closeInstruction.parsed?.type == "closeAccount" {
                    guard let source = closeInstruction.parsed?.info.destination else { return nil }
                    sourceAddress = source
                    guard let (newSourceWallet, newSourceChange) = try await parseToken(
                        transactionInfo,
                        for: sourceAddress
                    ) else { return nil }

                    sourceWallet = newSourceWallet
                    sourceChange = newSourceChange
                }
            }
        }

        // Swap to native SOL
        if destinationChange == .zero, swapInstructionIndex + 1 < totalInstructions {
            let closeInstruction = transactionInfo.transaction.message.instructions[swapInstructionIndex + 1]
            if closeInstruction.programId == TokenProgram.id.base58EncodedString {
                if closeInstruction.parsed?.type == "closeAccount" {
                    guard let destination = closeInstruction.parsed?.info.destination else { return nil }
                    destinationAddress = destination
                    guard let (newDestinationWallet, newDestinationChange) = try await parseToken(
                        transactionInfo,
                        for: destinationAddress
                    ) else { return nil }

                    destinationWallet = newDestinationWallet
                    destinationChange = newDestinationChange
                }
            }
        }

        return SwapInfo(
            source: sourceWallet,
            sourceAmount: sourceChange,
            destination: destinationWallet,
            destinationAmount: destinationChange,
            accountSymbol: config.symbolView
        )
    }

    func parseToken(_ transactionInfo: TransactionInfo,
                    for address: String) async throws -> (wallet: Wallet, amount: Double)?
    {
        guard let addressIndex = transactionInfo.transaction.message.accountKeys
            .firstIndex(where: { $0.publicKey.base58EncodedString == address }) else { return nil }

        let mintAddress: String = transactionInfo.meta?.postTokenBalances?
            .first(where: { $0.accountIndex == addressIndex })?.mint ?? Token.nativeSolana.address

        let preWalletBalance: Lamports
        if mintAddress == Token.nativeSolana.address {
            preWalletBalance = transactionInfo.meta?.preBalances?[addressIndex] ?? 0
        } else {
            preWalletBalance = transactionInfo.meta?.preTokenBalances?
                .first(where: { $0.accountIndex == addressIndex })?.uiTokenAmount.amountInUInt64 ?? 0
        }
        let preBalance: Double
        let postBalance: Double
        if mintAddress == Token.nativeSolana.address {
            preBalance = transactionInfo.meta?.preBalances?[addressIndex]
                .convertToBalance(decimals: Token.nativeSolana.decimals) ?? 0
            postBalance = transactionInfo.meta?.postBalances?[addressIndex]
                .convertToBalance(decimals: Token.nativeSolana.decimals) ?? 0
        } else {
            preBalance = transactionInfo.meta?.preTokenBalances?
                .first(where: { $0.accountIndex == addressIndex })?.uiTokenAmount.uiAmount ?? 0
            postBalance = transactionInfo.meta?.postTokenBalances?
                .first(where: { $0.accountIndex == addressIndex })?.uiTokenAmount.uiAmount ?? 0
        }

        let sourceToken: Token = try await tokensRepository.getTokenWithMint(mintAddress)

        let wallet = Wallet(
            pubkey: try? PublicKey(string: address).base58EncodedString,
            lamports: preWalletBalance,
            token: sourceToken
        )

        let amount = abs(postBalance - preBalance)

        return (wallet, amount)
    }
}
