// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

@available(* , deprecated, renamed: "SwapInfo")
public typealias SwapTransaction = SwapInfo

/// A struct that contains all information about swapping.
public struct SwapInfo: Hashable {
  /// A direction of swap on depends on account symbol view.
  public enum Direction {
    /// The spending swap transaction
    ///
    /// [A] -> B
    case spend

    /// The receiving swap transaction
    ///
    /// A -> [B]
    case receive

    /// The transaction is intermediate between two tokens.
    ///
    /// A -> [B] -> C
    case transitive
  }

  /// A source wallet
  public let source: Wallet?

  /// A swapping amount in source wallet
  public let sourceAmount: Double?

  /// A destination wallet
  public let destination: Wallet?

  /// A receiving amount in destination wallet
  public let destinationAmount: Double?

  /// A account symbol view.
  ///
  /// Depends on this value will define a direction of transaction
  public var accountSymbol: String?

  public init(
    source: Wallet?,
    sourceAmount: Double?,
    destination: Wallet?,
    destinationAmount: Double?,
    accountSymbol: String?
  ) {
    self.source = source
    self.sourceAmount = sourceAmount
    self.destination = destination
    self.destinationAmount = destinationAmount
    self.accountSymbol = accountSymbol
  }

  static var empty: Self {
    SwapInfo(
      source: nil,
      sourceAmount: nil,
      destination: nil,
      destinationAmount: nil,
      accountSymbol: nil
    )
  }

  /// Current direction of transactin.
  ///
  /// This value is calculated using account symbol view
  public var direction: Direction {
    if accountSymbol == source?.token.symbol {
      return .spend
    }
    if accountSymbol == destination?.token.symbol {
      return .receive
    }
    return .transitive
  }

  @available(*, deprecated, renamed: "accountSymbol")
  public var myAccountSymbol: String? { accountSymbol }
}

extension SwapInfo: Info {
  public var amount: Double? {
    switch direction {
    case .spend: return -(sourceAmount ?? 0)
    case .receive: return destinationAmount ?? 0
    case .transitive: return destinationAmount ?? 0
    }
  }

  public var symbol: String? {
    switch direction {
    case .spend: return source?.token.symbol
    case .receive: return destination?.token.symbol
    case .transitive: return destination?.token.symbol
    }
  }
    
  public var mintAddress: String? {
    switch direction {
    case .spend: return source?.token.address
    case .receive: return destination?.token.address
    case .transitive: return destination?.token.address
    }
  }
}
