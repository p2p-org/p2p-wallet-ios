//
//  SellTransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/12/2022.
//

import Foundation
import Combine

/// Repository that control the flow of sell transactions
protocol SellTransactionsRepository {
    /// Publisher that emit sell transactions every time when any transaction is updated
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> { get }
}

/// Mock SellTransactionsRepository
final class SellTransactionsRepositoryImpl: SellTransactionsRepository {

    // MARK: - Properties

    let transactions = CurrentValueSubject<[SellDataServiceTransaction], Never>([])
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> {
        transactions.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer

    init() {
        // FIXME: - Replace mock later
        let solPrice = 13.1
        let fakeDepositWalletPrefix = "CMNyyCXkAQ5cfFS2zQEg6YPzd8fpHvMFbbbmUfjoPp1"
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [unowned self] in
            transactions.send([
                .init(
                    id: UUID().uuidString,
                    createdAt: Date().addingTimeInterval(-2.0 * 60), // 2 minutes ago
                    status: .waitingForDeposit,
                    baseCurrencyAmount: 2,
                    quoteCurrencyAmount: 2 * solPrice,
                    usdRate: solPrice,
                    eurRate: solPrice,
                    gbpRate: solPrice,
                    depositWallet: fakeDepositWalletPrefix + "2"
                ),
                .init(
                    id: UUID().uuidString,
                    createdAt: Date().addingTimeInterval(-3.0 * 60), // 3 minutes ago
                    status: .pending,
                    baseCurrencyAmount: 3,
                    quoteCurrencyAmount: 3 * solPrice,
                    usdRate: solPrice,
                    eurRate: solPrice,
                    gbpRate: solPrice,
                    depositWallet: fakeDepositWalletPrefix + "3"
                ),
                .init(
                    id: UUID().uuidString,
                    createdAt: Date().addingTimeInterval(-4.0 * 60), // 4 minutes ago
                    status: .failed,
                    baseCurrencyAmount: 4,
                    quoteCurrencyAmount: 4 * solPrice,
                    usdRate: solPrice,
                    eurRate: solPrice,
                    gbpRate: solPrice,
                    depositWallet: fakeDepositWalletPrefix + "4"
                ),
                .init(
                    id: UUID().uuidString,
                    createdAt: Date().addingTimeInterval(-5.0 * 60), // 5 minutes ago
                    status: .completed,
                    baseCurrencyAmount: 5,
                    quoteCurrencyAmount: 5 * solPrice,
                    usdRate: solPrice,
                    eurRate: solPrice,
                    gbpRate: solPrice,
                    depositWallet: fakeDepositWalletPrefix + "5"
                )
            ])
        }
    }
}
