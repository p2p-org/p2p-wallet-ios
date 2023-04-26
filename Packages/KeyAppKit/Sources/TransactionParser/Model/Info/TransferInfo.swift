// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

@available(*, deprecated, renamed: "TransferInfo")
public typealias TransferTransaction = TransferInfo

/// A struct that contains all information about transfer.
public struct TransferInfo: Hashable {
  /// The type of transfer in context of current account view.
  public enum TransferType {
    case send, receive
  }

  /// The source account address.
  public let source: Wallet?

  /// The destination account address.
  public let destination: Wallet?

  public let authority: String?

  public let destinationAuthority: String?

  /// The amount of transfer
  public let rawAmount: Double?

  /// The current account address view.
  ///
  /// Depends on that will define it's a send or receive transaction.
  public let account: String?

  public init(
    source: Wallet?,
    destination: Wallet?,
    authority: String?,
    destinationAuthority: String?,
    rawAmount: Double?,
    account: String?
  ) {
    self.source = source
    self.destination = destination
    self.authority = authority
    self.destinationAuthority = destinationAuthority
    self.rawAmount = rawAmount
    self.account = account
  }

  /// A current transfer type that depends on account view.
  public var transferType: TransferType? {
    (source?.pubkey == account || authority == account) ? .send : .receive
  }

  @available(*, deprecated, renamed: "account")
  public var myAccount: String? { account }
}

extension TransferInfo: Info {
  public var amount: Double? {
    var amount = rawAmount ?? 0
    if transferType == .send { amount = -amount }
    return amount
  }

  public var symbol: String? { source?.token.symbol ?? destination?.token.symbol ?? "" }
    
  public var mintAddress: String? { source?.token.address ?? destination?.token.address ?? "" }
}
