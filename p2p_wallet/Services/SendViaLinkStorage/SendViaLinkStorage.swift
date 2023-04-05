import Foundation
import Resolver
import SolanaSwift
import SwiftyUserDefaults
import Combine
import KeychainSwift

/// Storage that handle SendViaLinkTransactions
protocol SendViaLinkStorage: Actor {
    
    /// Save transaction to storage
    @discardableResult
    func save(transaction: SendViaLinkTransactionInfo) -> Bool
    
    /// Remove transaction with seed from storage
    @discardableResult
    func remove(seed: String) -> Bool
    
    /// Get all transactions
    func getTransactions() -> [SendViaLinkTransactionInfo]
    
    /// Transaction publisher to handle transaction
    nonisolated var transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never> { get }
}

actor SendViaLinkStorageImpl: SendViaLinkStorage {
    // MARK: - Dependencies
    
    @Injected private var userWalletManager: UserWalletManager
    
    private var localKeychain = KeychainSwift()
    
    // MARK: - Properties
    
    nonisolated private let transactionsSubject = CurrentValueSubject<[SendViaLinkTransactionInfo], Never>([])
    
    private let sendViaLinkTransactionsKeychainKey = "SendViaLinkStorageImpl.sendViaLinkTransactionsKeychainKey"

    // MARK: - Computed properties
    
    var userPubkey: String? {
        userWalletManager.wallet?.account.publicKey.base58EncodedString
    }
    
    nonisolated var transactionsPublisher: AnyPublisher<[SendViaLinkTransactionInfo], Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializer

    init() {
        Task {
            // retrieve transaction
            transactionsSubject.send(await getTransactions())
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
        
        // notify
        transactionsSubject.send(transactions)
        
        // save
        return save(transactions: transactions)
    }
    
    func remove(seed: String) -> Bool {
        // get seeds from keychain
        var transactions = getTransactions()
        
        // remove seed
        transactions.removeAll(where: { $0.seed == seed })
        
        // notify
        transactionsSubject.send(transactions)
        
        // save
        return save(transactions: transactions)
    }
    
    func getTransactions() -> [SendViaLinkTransactionInfo] {
        guard let userPubkey,
              let data = localKeychain.getData(sendViaLinkTransactionsKeychainKey),
              let dict = try? JSONDecoder().decode([String: [SendViaLinkTransactionInfo]].self, from: data)
        else {
            return []
        }
        return dict[userPubkey] ?? []
    }
    
    // MARK: - Keychain

    private func save(transactions: [SendViaLinkTransactionInfo]) -> Bool {
        // assert user pubkey
        guard let userPubkey else {
            return false
        }
        
        // assure that dictionary is alway non-optional
        var newValue = [String: [SendViaLinkTransactionInfo]]()
        if let data = localKeychain.getData(sendViaLinkTransactionsKeychainKey),
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
        
        // save to Keychain
        return localKeychain.set(data, forKey: sendViaLinkTransactionsKeychainKey)
    }
}
