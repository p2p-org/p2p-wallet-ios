// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A strategy for parsing serum transactions.
public class SerumSwapParseStrategy: TransactionParseStrategy {
  private let tokensRepository: TokensRepository

  init(tokensRepository: TokensRepository) { self.tokensRepository = tokensRepository }

  public func isHandlable(
    with transactionInfo: SolanaSwift.TransactionInfo
  ) -> Bool {
    let instructions = transactionInfo.transaction.message.instructions
    return instructions.contains { $0.programId == PublicKey.serumSwapPID.base58EncodedString }
  }

  public func parse(
    _ transactionInfo: SolanaSwift.TransactionInfo,
    config configuration: Configuration
  ) async throws -> AnyHashable? {
    let instructions = transactionInfo.transaction.message.instructions
    let innerInstruction = transactionInfo.meta?.innerInstructions?
      .first(where: {
        $0.instructions
          .contains(where: { $0.programId == PublicKey.serumSwapPID.base58EncodedString })
      })

    let swapInstructionIndex = serumInstruction(transactionInfo: transactionInfo)!
    guard let swapInstruction = instructions[safe: swapInstructionIndex] else { return nil }
    let preTokenBalances = transactionInfo.meta?.preTokenBalances

    // get all mints
    guard
      var mints = preTokenBalances?.map(\.mint).unique,
      mints.count >= 2 // max: 3
    else {
      return nil
    }

    // transitive swap: remove usdc or usdt if exists
    if mints.count == 3 {
      mints.removeAll(where: { $0.isUSDxMint })
    }

    // define swap type
    let isTransitiveSwap = !mints.contains(where: \.isUSDxMint)

    // assert
    guard let accounts = swapInstruction.accounts else { return nil }
    if isTransitiveSwap, accounts.count != 27 { return nil }
    if !isTransitiveSwap, accounts.count != 16 { return nil }

    // get from and to address
    var fromAddress: String
    var toAddress: String

    if isTransitiveSwap { // transitive
      fromAddress = accounts[6]
      toAddress = accounts[21]
    } else { // direct
      fromAddress = accounts[10]
      toAddress = accounts[12]

      if mints.first?.isUSDxMint == true && mints.last?.isUSDxMint == false {
        Swift.swap(&fromAddress, &toAddress)
      }
    }

    // amounts
    var fromAmount: Lamports?
    var toAmount: Lamports?

    // from amount
    if let instruction = innerInstruction?.instructions
      .first(where: { $0.parsed?.type == "transfer" }),
      let amountString = instruction.parsed?.info.amount,
      let amount = Lamports(amountString)
    {
      fromAmount = amount
    }

    // to amount
    if let instruction = innerInstruction?.instructions
      .first(where: { $0.parsed?.type == "transfer" }),
      let amountString = instruction.parsed?.info.amount,
      let amount = Lamports(amountString)
    {
      toAmount = amount
    }

    // if swap from native sol, detect if from or to address is a new account
    if let createAccountInstruction = instructions
      .first(where: {
        $0.parsed?.type == "createAccount" &&
          $0.parsed?.info.newAccount == fromAddress
      }),
      let realSource = createAccountInstruction.parsed?.info.source
    {
      fromAddress = realSource
    }

    let sourceToken = try await tokensRepository.getTokenWithMint(mints[0])
    let destinationToken = try await tokensRepository.getTokenWithMint(mints[1])

    let sourceWallet = Wallet(
      pubkey: fromAddress,
      lamports: 0, // post token balance?
      token: sourceToken
    )

    let destinationWallet = Wallet(
      pubkey: toAddress,
      lamports: 0, // post token balances
      token: destinationToken
    )

    return SwapInfo(
      source: sourceWallet,
      sourceAmount: fromAmount?.convertToBalance(decimals: sourceToken.decimals),
      destination: destinationWallet,
      destinationAmount: toAmount?.convertToBalance(decimals: destinationToken.decimals),
      accountSymbol: configuration.symbolView
    )
  }

  func serumInstruction(transactionInfo: SolanaSwift.TransactionInfo) -> Int? {
    let instructions = transactionInfo.transaction.message.instructions
    return instructions.lastIndex(
      where: {
        $0.programId == PublicKey.serumSwapPID.base58EncodedString
      }
    )
  }
}

extension String {
  var isUSDxMint: Bool {
    self == PublicKey.usdtMint.base58EncodedString ||
      self == PublicKey.usdcMint.base58EncodedString
  }
}
