// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import P2PSwift

public typealias SolendSymbol = P2PSwift.SolendSymbol
public typealias SolendUserDeposit = P2PSwift.SolendUserDeposit
public typealias SolendDepositFee = P2PSwift.SolendFee
public typealias SolendConfigAsset = P2PSwift.SolendConfigAsset

public struct SolendMarketInfo: Codable, Hashable {
    public let symbol: String
    public let currentSupply: String
    public let depositLimit: String
    public let supplyInterest: String

    public init(symbol: String, currentSupply: String, depositLimit: String, supplyInterest: String) {
        self.symbol = symbol
        self.currentSupply = currentSupply
        self.depositLimit = depositLimit
        self.supplyInterest = supplyInterest
    }
}

