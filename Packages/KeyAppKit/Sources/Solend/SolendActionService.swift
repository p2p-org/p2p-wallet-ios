// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import SolanaSwift
import FeeRelayerSwift

public enum SolendActionStatus: Codable, Equatable {
    case processing
    case success
    case failed(msg: String)
}

public enum SolendActionType: Codable, Equatable {
    case deposit
    case withdraw
}

public struct SolendFeePayer: Codable, Equatable {
    public let address: String
    public let mint: String
    
    public init(address: String, mint: String) {
        self.address = address
        self.mint = mint
    }
}

public struct SolendAction: Codable, Equatable {
    public let type: SolendActionType
    public internal(set) var transactionID: String?
    public internal(set) var status: SolendActionStatus
    public let amount: UInt64
    public let symbol: SolendSymbol
    
    public init(
        type: SolendActionType,
        transactionID: String?,
        status: SolendActionStatus,
        amount: UInt64,
        symbol: SolendSymbol
    ) {
        self.type = type
        self.transactionID = transactionID
        self.status = status
        self.amount = amount
        self.symbol = symbol
    }
}

public protocol SolendActionService {
    var currentAction: AnyPublisher<SolendAction?, Never> { get }
    func getCurrentAction() -> SolendAction?
    func clearAction() throws

    func depositFee(amount: UInt64, symbol: SolendSymbol) async throws -> FeeAmount
    func withdrawFee(amount: UInt64, symbol: SolendSymbol) async throws -> FeeAmount

    func deposit(
        amount: UInt64,
        symbol: SolendSymbol,
        feePayer: FeeRelayerSwift.TokenAccount?
    ) async throws
    
    func withdraw(
        amount: UInt64,
        symbol: SolendSymbol,
        feePayer: FeeRelayerSwift.TokenAccount?
    ) async throws
}
