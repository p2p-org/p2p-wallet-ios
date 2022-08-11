//
//  SendTokenTokenAndAmountHandler.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/12/2021.
//

import Combine
import Foundation
import SolanaSwift

protocol SendTokenTokenAndAmountHandler {
    // MARK: - @Published var wallet

    // Define wallet (wrapped value)
    var wallet: Wallet? { get }
    // Define wallet Published property wrapper
    func setWallet(_ wallet: Wallet?)
    // Define wallet publisher
    var walletPublisher: AnyPublisher<Wallet?, Never> { get }

    // MARK: - @Published var amount

    // Define amount (wrapped value)
    var amount: Double? { get }
    // Define amount Published property wrapper
    func setAmount(_ amount: Double?)
    // Define amount publisher
    var amountPublisher: AnyPublisher<Double?, Never> { get }
}
