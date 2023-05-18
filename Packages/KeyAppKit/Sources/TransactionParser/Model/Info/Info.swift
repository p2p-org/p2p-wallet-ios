// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// An abstract interface that allows to calculate the amount of token that the transaction is responsible for.
public protocol Info {
  /// The amount of token in symbol.
  var amount: Double? { get }
  
  /// The token symbol.
  var symbol: String? { get }
  
  /// Token address
  var mintAddress: String? { get }
}
