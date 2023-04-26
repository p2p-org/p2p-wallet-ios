// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A strategy for parsing transfer transactions.
public class TransferParseStrategy: TransactionParseStrategy {
  private let apiClient: SolanaAPIClient
  private let tokensRepository: SolanaTokensRepository

  init(apiClient: SolanaAPIClient, tokensRepository: SolanaTokensRepository) {
    self.apiClient = apiClient
    self.tokensRepository = tokensRepository
  }
  
  public func isHandlable(
    with transactionInfo: TransactionInfo
  ) -> Bool {
    let instructions = transactionInfo.transaction.message.instructions
    return (instructions.count == 1 || instructions.count == 4 || instructions.count == 2) &&
      (instructions.last?.parsed?.type == "transfer" || instructions.last?.parsed?
        .type == "transferChecked")
  }
  
  public func parse(
    _ transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> AnyHashable? {
    let instructions = transactionInfo.transaction.message.instructions
    if instructions.last?.programId == SystemProgram.id.base58EncodedString {
      // SOL to SOL
      return try await parseSOLTrasnfer(transactionInfo, config: configuration)
    } else {
      // SPL to SPL token
      return try await parseSPLTransfer(transactionInfo, config: configuration)
    }
  }

  func parseSOLTrasnfer(
    _ transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> TransferInfo {
    let instructions = transactionInfo.transaction.message.instructions

    // get pubkeys
    let transferInstruction = instructions.last
    let sourcePubkey = transferInstruction?.parsed?.info.source
    let destinationPubkey = transferInstruction?.parsed?.info.destination

    // get lamports
    let lamports = transferInstruction?.parsed?.info.lamports ??
      UInt64(transferInstruction?.parsed?.info.amount ?? transferInstruction?.parsed?.info.tokenAmount?
        .amount ?? "0")

    let source = Wallet.nativeSolana(pubkey: sourcePubkey, lamport: nil)
    let destination = Wallet.nativeSolana(pubkey: destinationPubkey, lamport: nil)

    return TransferInfo(
      source: source,
      destination: destination,
      authority: nil,
      destinationAuthority: nil,
      rawAmount: lamports?.convertToBalance(decimals: source.token.decimals),
      account: configuration.accountView
    )
  }

  func parseSPLTransfer(
    _ transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> TransferInfo? {
    let instructions = transactionInfo.transaction.message.instructions
    let postTokenBalances = transactionInfo.meta?.postTokenBalances ?? []
    let accountKeys = transactionInfo.transaction.message.accountKeys

    // get pubkeys
    let transferInstruction = instructions.last
    let authority = transferInstruction?.parsed?.info.authority
    let sourcePubkey = transferInstruction?.parsed?.info.source
    let destinationPubkey = transferInstruction?.parsed?.info.destination

    // get lamports
    let lamports = transferInstruction?.parsed?.info.lamports ??
      UInt64(transferInstruction?.parsed?.info.amount ?? transferInstruction?.parsed?.info.tokenAmount?
        .amount ?? "0")

    var destinationAuthority: String?
    if let createATokenInstruction = instructions
      .first(where: { $0.programId == AssociatedTokenProgram.id.base58EncodedString })
    {
      // send to associated token
      destinationAuthority = createATokenInstruction.parsed?.info.wallet
    } else if let initializeAccountInstruction = instructions
      .first(where: {
        $0.programId == TokenProgram.id.base58EncodedString && $0.parsed?.type == "initializeAccount"
      })
    {
      // send to new token address (deprecated)
      destinationAuthority = initializeAccountInstruction.parsed?.info.owner
    }

    // Define token with mint
    var transferInfo: TransferInfo
    if let tokenBalance = postTokenBalances.first(where: { !$0.mint.isEmpty }) {
      // if the wallet that is opening is SOL, then modify myAccount
      var myAccount = configuration.accountView
      if sourcePubkey != myAccount,
         destinationPubkey != myAccount,
         accountKeys.count >= 4
      {
        // send
        if myAccount == accountKeys[0].publicKey.base58EncodedString {
          myAccount = sourcePubkey
        }

        if myAccount == accountKeys[3].publicKey.base58EncodedString {
          myAccount = destinationPubkey
        }
      }

      let token = try await tokensRepository.getTokenWithMint(tokenBalance.mint)
      let source = Wallet(pubkey: sourcePubkey, lamports: nil, token: token)
      let destination = Wallet(pubkey: destinationPubkey, lamports: nil, token: token)
      transferInfo = TransferInfo(
        source: source,
        destination: destination,
        authority: authority,
        destinationAuthority: destinationAuthority,
        rawAmount: lamports?.convertToBalance(decimals: source.token.decimals),
        account: myAccount
      )
    } else {
      // Mint not found
      let accountInfo: BufferInfo<AccountInfo>? = try await apiClient
        .getAccountInfo(account: sourcePubkey, or: destinationPubkey)
      let token = try await tokensRepository.getTokenWithMint(accountInfo?.data.mint.base58EncodedString)
      let source = Wallet(pubkey: sourcePubkey, lamports: nil, token: token)
      let destination = Wallet(pubkey: destinationPubkey, lamports: nil, token: token)

      transferInfo = TransferInfo(
        source: source,
        destination: destination,
        authority: authority,
        destinationAuthority: destinationAuthority,
        rawAmount: lamports?.convertToBalance(decimals: source.token.decimals),
        account: configuration.accountView
      )
    }

    if transferInfo.destinationAuthority != nil { return transferInfo }
    guard let account = transferInfo.destination?.pubkey else { return transferInfo }

    do {
      let accountInfo: BufferInfo<AccountInfo>? = try await apiClient.getAccountInfo(account: account)
      return TransferInfo(
        source: transferInfo.source,
        destination: transferInfo.destination,
        authority: transferInfo.authority,
        destinationAuthority: accountInfo?.data.owner.base58EncodedString,
        rawAmount: transferInfo.rawAmount,
        account: configuration.accountView
      )
    } catch {
      return TransferInfo(
        source: transferInfo.source,
        destination: transferInfo.destination,
        authority: transferInfo.authority,
        destinationAuthority: nil,
        rawAmount: transferInfo.rawAmount,
        account: configuration.accountView
      )
    }
  }
}
