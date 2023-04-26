// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift
import Cache

/// A default implementation for parsing transaction fee.
public class DefaultFeeParseStrategy: FeeParseStrategy {
  let apiClient: SolanaAPIClient
  let cache: Cache<String, Any>

  /// Initialize a default strategy with build-in cache system.
  public init(apiClient: SolanaAPIClient) {
    self.apiClient = apiClient
    cache = Cache()
  }

  /// Initialize a default strategy.
  public init(apiClient: SolanaAPIClient, cache: Cache<String, Any>) {
    self.apiClient = apiClient
    self.cache = cache
  }

  public func calculate(
    transactionInfo: TransactionInfo,
    feePayers feePayerPubkeys: [String]
  ) async throws -> FeeAmount {
    let confirmedTransaction = transactionInfo.transaction

    // Prepare
    let lamportsPerSignature: Lamports = try await getLamportPerSignature()
    let minRentExemption: Lamports = try await getRentException()

    // get creating and closing account instruction
    let createTokenAccountInstructions = confirmedTransaction.message.instructions
      .filter {
        $0.programId == TokenProgram.id.base58EncodedString && $0.parsed?
          .type == "create"
      }
    let createWSOLAccountInstructions = confirmedTransaction.message.instructions
      .filter {
        $0.programId == SystemProgram.id.base58EncodedString && $0.parsed?
          .type == "createAccount"
      }
    let closeAccountInstructions = confirmedTransaction.message.instructions
      .filter {
        $0.programId == TokenProgram.id.base58EncodedString && $0.parsed?
          .type == "closeAccount"
      }
    let depositAccountsInstructions = closeAccountInstructions.filter { closeInstruction in
      createWSOLAccountInstructions
        .contains { $0.parsed?.info.newAccount == closeInstruction.parsed?.info.account } ||
        createTokenAccountInstructions
        .contains { $0.parsed?.info.account == closeInstruction.parsed?.info.account }
    }

    // get fee
    let numberOfCreatedAccounts = createTokenAccountInstructions.count + createWSOLAccountInstructions
      .count - depositAccountsInstructions.count
    let numberOfDepositAccounts = depositAccountsInstructions.count

    var transactionFee = lamportsPerSignature * UInt64(confirmedTransaction.signatures.count)
    let accountCreationFee = minRentExemption * UInt64(numberOfCreatedAccounts)
    let depositFee = minRentExemption * UInt64(numberOfDepositAccounts)

    // check last compensation transaction
    if let firstPubkey = confirmedTransaction.message.accountKeys.first?.publicKey.base58EncodedString,
       feePayerPubkeys.contains(firstPubkey)
    {
        // TODO: - Fix later
        transactionFee = 0
//      // check last "returning instruction"
//      if let lastTransaction = confirmedTransaction.message.instructions.last,
//         // returning transaction must have RelayProgram id
//         lastTransaction.programId == RelayProgram.id(network: apiClient.endpoint.network)
//           .base58EncodedString,
//           // get inner transaction to get amount that have been returned
//           let innerInstruction = transactionInfo.meta?.innerInstructions?
//             .first(where: { $0.index == UInt32(confirmedTransaction.message.instructions.count - 1) }),
//             let innerInstructionAmount = innerInstruction.instructions.first?.parsed?.info.lamports,
//             // got the amount, check if user had to pay the transaction fee (not account creation fee)
//             innerInstructionAmount > accountCreationFee + depositFee
//      {
//        // do nothing
//      } else {
//        // mark transaction as paid by P2p org
//        transactionFee = 0
//      }
    }

    return .init(transaction: transactionFee, accountBalances: accountCreationFee, deposit: depositFee)
  }

  internal func getRentException() async throws -> Lamports {
    let kRentExemption = "rentExemption"

    // Load from cache
    if let rentExemption = await cache.value(forKey: kRentExemption) as? Lamports { return rentExemption }

    // Load from network
    let rentExemption = try await apiClient.getMinimumBalanceForRentExemption(span: 65)

    // Store in cache
    await cache.insert(rentExemption, forKey: kRentExemption)
    return rentExemption
  }

  internal func getLamportPerSignature() async throws -> Lamports {
    let kLamportsPerSignature = "lamportsPerSignature"

    // Load from cache
    if let lamportsPerSignature: Lamports = await cache
      .value(forKey: kLamportsPerSignature) as? Lamports { return lamportsPerSignature }

    // Load from network
    let fee = try await apiClient.getFees(commitment: nil)

    // Default value in case network in not available
    let lamportsPerSignature = fee.feeCalculator?.lamportsPerSignature ?? 5000

    // Store in cache
    await cache.insert(lamportsPerSignature, forKey: kLamportsPerSignature)

    return lamportsPerSignature
  }
}
