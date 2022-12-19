//
//  SellTransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/12/2022.
//

import Foundation
import Combine
import Resolver

/// Repository that control the flow of sell transactions
protocol SellTransactionsRepository {
    /// Publisher that emit sell transactions every time when any transaction is updated
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> { get }
    
    /// Get current fetched transactions
    var currentTransactions: [SellDataServiceTransaction] { get }
}

/// Mock SellTransactionsRepository
final class SellTransactionsRepositoryImpl: SellTransactionsRepository {
    
    // MARK: - Dependencies
    
    @Injected private var sellDataService: any SellDataService
    @Injected private var userWalletManager: UserWalletManager

    // MARK: - Properties
    
    private let refreshingRate: TimeInterval = 5.0 // 5 sec

    let transactions = CurrentValueSubject<[SellDataServiceTransaction], Never>([])
    
    var updatingTask: Task<Void, Never>?
    
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> {
        transactions.eraseToAnyPublisher()
    }
    
    var currentTransactions: [SellDataServiceTransaction] {
        transactions.value
    }
    
    // MARK: - Initializer

    init() {
        Timer.scheduledTimer(withTimeInterval: refreshingRate, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    private func update() {
        // cancel previous task
        updatingTask?.cancel()
        
        // update
        updatingTask = Task { [weak self] in
            guard let self = self, let id = self.userWalletManager.wallet?.moonpayExternalClientId else {return}
            guard let transactions = try? await self.sellDataService.transactions(id: id)
            else { return }
            self.transactions.send(transactions)
        }
    }
}
