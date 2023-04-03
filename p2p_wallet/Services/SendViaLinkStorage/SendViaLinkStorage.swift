import Foundation
import Resolver
import SolanaSwift
import SwiftyUserDefaults
import Combine

/// Storage that handle SendViaLinkTransactions
protocol SendViaLinkStorage {
    
    /// Save transaction to storage
    @discardableResult
    func save(transaction: SendViaLinkTransactionInfo) -> Bool
    
    /// Remove transaction with seed from storage
    @discardableResult
    func remove(seed: String) -> Bool
    
    /// Get all transactions
    func getTransactions() -> [SendViaLinkTransactionInfo]
    
    /// Transaction publisher to handle transaction
    var transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never> { get }
}

final class SendViaLinkStorageImpl: SendViaLinkStorage {
    // MARK: - Dependencies
    
    @Injected private var userWalletManager: UserWalletManager
    
    // MARK: - Properties
    
    private var subscription: DefaultsDisposable?
    private let transactionsSubject = CurrentValueSubject<[SendViaLinkTransactionInfo], Never>([])
    
    // MARK: - Computed properties
    
    var userPubkey: String? {
        userWalletManager.wallet?.account.publicKey.base58EncodedString
    }
    
    var transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer

    init() {
        // retrieve transaction
        transactionsSubject.send(getTransactions())

        // observe changes
        subscription = Defaults.observe(\.sendViaLinkTransactions) { [weak self] transactions in
            guard let newValue = self?.getTransactions()
            else { return }
            self?.transactionsSubject.send(newValue)
        }
    }
    
    // MARK: - Actions
    
    @discardableResult
    func save(transaction: SendViaLinkTransactionInfo) -> Bool {
        // get seeds
        var transactions = getTransactions()
        
        // assert that seeds has not already existed
        guard !transactions.contains(where: { $0.seed == transaction.seed }) else {
            return true
        }
        
        // append seed
        transactions.insert(transaction, at: 0)
        
        // save
        return save(transactions: transactions)
    }
    
    func remove(seed: String) -> Bool {
        // get seeds from keychain
        var transactions = getTransactions()
        
        // remove seed
        transactions.removeAll(where: { $0.seed == seed })
        
        // save
        return save(transactions: transactions)
    }
    
    func getTransactions() -> [SendViaLinkTransactionInfo] {
        guard let userPubkey,
              let data = Defaults.sendViaLinkTransactions,
              let dict = try? JSONDecoder().decode([String: [SendViaLinkTransactionInfo]].self, from: data)
        else {
            return []
        }
        return dict[userPubkey] ?? []
    }
    
    private func save(transactions: [SendViaLinkTransactionInfo]) -> Bool {
        // assert user pubkey
        guard let userPubkey else {
            return false
        }
        
        // assure that dictionary is alway non-optional
        var newValue = [String: [SendViaLinkTransactionInfo]]()
        if let data = Defaults.sendViaLinkTransactions,
           let dict = try? JSONDecoder().decode([String: [SendViaLinkTransactionInfo]].self, from: data)
        {
            newValue = dict
        }
        
        // modify value
        newValue[userPubkey] = transactions
        
        // encode to data
        guard let data = try? JSONEncoder().encode(newValue) else {
            return false
        }
        
        // save to UserDefaults
        Defaults.sendViaLinkTransactions = data
        return true
    }
}