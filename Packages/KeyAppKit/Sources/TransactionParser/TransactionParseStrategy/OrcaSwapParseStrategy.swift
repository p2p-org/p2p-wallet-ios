// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A strategy for orca swap transactions.
public class OrcaSwapParseStrategy: TransactionParseStrategy {
  /// The list of orca program signatures that will be parsed by this strategy
  private static let orcaProgramSignatures = [
    PublicKey.orcaSwapId(version: 1).base58EncodedString,
    PublicKey.orcaSwapId(version: 2).base58EncodedString,
    "9qvG1zUp8xF1Bi4m6UdRNby1BAAuaDrUxSpv4CmRRMjL", /* main deprecated */
    "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8", /* main deprecated */
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
    let innerInstructions = transactionInfo.meta?.innerInstructions

    switch true {
    case isLiquidityToPool(innerInstructions: innerInstructions): return nil
    case isBurn(innerInstructions: innerInstructions): return nil
    default:
      return try await _parse(
        transactionInfo: transactionInfo,
        config: configuration
      )
    }
  }

  func _parse(
    transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> AnyHashable? {
    try Task.checkCancellation()

    // Filter swap instructions
    let swapInstructions = transactionInfo.instructionsData().filter {
      Self.orcaProgramSignatures.contains($0.instruction.programId)
    }

    // A swap should have at lease one orca instruction.
    guard !swapInstructions.isEmpty else {
      return try await parseFailedTransaction(transactionInfo: transactionInfo, accountSymbol: configuration.symbolView)
    }

    // Get source and target
    guard
      let source: ParsedInstruction = swapInstructions.first?.innerInstruction?.instructions.first,
      let destination: ParsedInstruction = swapInstructions.last?.innerInstruction?.instructions.last
    else {
      return try await parseFailedTransaction(transactionInfo: transactionInfo, accountSymbol: configuration.symbolView)
    }

    guard let sourceInfo: ParsedInstruction.Parsed.Info = source.parsed?.info else { return nil }
    guard let destinationInfo: ParsedInstruction.Parsed.Info = destination.parsed?.info else { return nil }

    // Get accounts info
    let (sourceAccount, destinationAccount): (BufferInfo<AccountInfo>?, BufferInfo<AccountInfo>?) = try await(
      apiClient
        .getAccountInfo(account: sourceInfo.source, or: sourceInfo.destination),
      apiClient
        .getAccountInfo(account: destinationInfo.source, or: destinationInfo.destination)
    )

    try Task.checkCancellation()

    // Get tokens info
    let (sourceToken, destinationToken): (Token, Token) = try await(
      tokensRepository.getTokenWithMint(sourceAccount?.data.mint.base58EncodedString),
      tokensRepository.getTokenWithMint(destinationAccount?.data.mint.base58EncodedString)
    )

    let sourceWallet = Wallet(
      pubkey: try? PublicKey(string: sourceInfo.source).base58EncodedString,
      lamports: sourceAccount?.lamports,
      token: sourceToken
    )

    let destinationWallet = Wallet(
      pubkey: try? PublicKey(string: destinationInfo.destination).base58EncodedString,
      lamports: destinationAccount?.lamports,
      token: destinationToken
    )

    let sourceAmountLamports = Lamports(sourceInfo.amount ?? "0")
    let destinationAmountLamports = Lamports(destinationInfo.amount ?? "0")

    return SwapInfo(
      source: sourceWallet,
      sourceAmount: sourceAmountLamports?.convertToBalance(decimals: sourceWallet.token.decimals),
      destination: destinationWallet,
      destinationAmount: destinationAmountLamports?
        .convertToBalance(decimals: destinationWallet.token.decimals),
      accountSymbol: configuration.symbolView
    )
  }

  func parseFailedTransaction(
    transactionInfo: TransactionInfo,
    accountSymbol: String?
  ) async throws -> SwapInfo? {
    try Task.checkCancellation()

    guard
      let postTokenBalances = transactionInfo.meta?.postTokenBalances,
      let approveInstruction = transactionInfo.transaction.message.instructions
        .first(where: { $0.parsed?.type == "approve" }),
        let sourceAmountString = approveInstruction.parsed?.info.amount,
        let sourceMint = postTokenBalances.first?.mint,
        let destinationMint = postTokenBalances.last?.mint
    else {
      return nil
    }

    let sourceToken = try await tokensRepository.getTokenWithMint(sourceMint)
    let destinationToken = try await tokensRepository.getTokenWithMint(destinationMint)

    let sourceWallet = Wallet(
      pubkey: approveInstruction.parsed?.info.source,
      lamports: Lamports(postTokenBalances.first?.uiTokenAmount.amount ?? "0"),
      token: sourceToken
    )

    let destinationWallet = Wallet(
      pubkey: destinationToken.symbol == "SOL" ? approveInstruction.parsed?.info.owner : nil,
      lamports: Lamports(postTokenBalances.last?.uiTokenAmount.amount ?? "0"),
      token: destinationToken
    )

    return SwapInfo(
      source: sourceWallet,
      sourceAmount: Lamports(sourceAmountString)?.convertToBalance(decimals: sourceWallet.token.decimals),
      destination: destinationWallet,
      destinationAmount: nil,
      accountSymbol: accountSymbol
    )
  }
}

private func isLiquidityToPool(innerInstructions: [InnerInstruction]?) -> Bool {
  guard let instructions = innerInstructions?.first?.instructions else { return false }
  switch instructions.count {
  case 3:
    return instructions[0].parsed?.type == "transfer" &&
      instructions[1].parsed?.type == "transfer" &&
      instructions[2].parsed?.type == "mintTo"
  default:
    return false
  }
}

/// Check the instruction is a burn
private func isBurn(innerInstructions: [InnerInstruction]?) -> Bool {
  guard let instructions = innerInstructions?.first?.instructions else { return false }
  switch instructions.count {
  case 3:
    return instructions.count == 3 &&
      instructions[0].parsed?.type == "burn" &&
      instructions[1].parsed?.type == "transfer" &&
      instructions[2].parsed?.type == "transfer"
  default:
    return false
  }
}
