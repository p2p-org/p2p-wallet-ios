// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

/// A default implementation of parser service.
public class TransactionParserServiceImpl: TransactionParserService {
  let strategies: [TransactionParseStrategy]
  let feeParserStrategy: FeeParseStrategy

  public init(strategies: [TransactionParseStrategy], feeParserStrategy: FeeParseStrategy) {
    self.strategies = strategies
    self.feeParserStrategy = feeParserStrategy
  }

  public static func `default`(apiClient: SolanaAPIClient) -> TransactionParserServiceImpl {
    let tokensRepository = TokensRepository(endpoint: apiClient.endpoint)

    return .init(
      strategies: [
        OrcaSwapParseStrategy(apiClient: apiClient, tokensRepository: tokensRepository),
        P2POrcaSwapWrapperParseStrategy(apiClient: apiClient, tokensRepository: tokensRepository),
        SerumSwapParseStrategy(tokensRepository: tokensRepository),
        CreationAccountParseStrategy(tokensRepository: tokensRepository),
        CloseAccountParseStrategy(tokensRepository: tokensRepository),
        TransferParseStrategy(apiClient: apiClient, tokensRepository: tokensRepository),
      ],
      feeParserStrategy: DefaultFeeParseStrategy(apiClient: apiClient)
    )
  }

  public func parse(
    _ transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> ParsedTransaction {
    var status = ParsedTransaction.Status.confirmed

    if transactionInfo.meta?.err != nil {
      let errorMessage = transactionInfo.meta?.logMessages?
        .first(where: { $0.contains("Program log: Error:") })?
        .replacingOccurrences(of: "Program log: Error: ", with: "")
      status = .error(errorMessage)
    }

    let (info, fee): (AnyHashable?, FeeAmount) = try await(
      parseTransaction(transactionInfo: transactionInfo, config: configuration),
      parseFee(transactionInfo: transactionInfo, config: configuration)
    )
    
    return ParsedTransaction(
      status: status,
      signature: transactionInfo.transaction.signatures.first,
      info: info,
      slot: transactionInfo.slot,
      blockTime: transactionInfo.blockTime?.asDate(),
      fee: fee,
      blockhash: transactionInfo.transaction.message.recentBlockhash
    )
  }

  /// Algorithm for choosing strategy
  ///
  /// The picking is depends on order of strategies. If strategy has been chosen, but it can't parse the transaction, the next strategy will try to parse.
  internal func parseTransaction(
    transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> AnyHashable? {
    for strategy in strategies {
      if strategy.isHandlable(with: transactionInfo) {
        let info = try await strategy.parse(transactionInfo, config: configuration)

        guard let info = info else { continue }
        return info
      }
    }

    return nil
  }

  private func parseFee(
    transactionInfo: TransactionInfo,
    config configuration: Configuration
  ) async throws -> FeeAmount {
    try await feeParserStrategy.calculate(transactionInfo: transactionInfo, feePayers: configuration.feePayers)
  }
}

private extension UInt64 {
  func asDate() -> Date {
    Date(timeIntervalSince1970: TimeInterval(self))
  }
}
