import Foundation
import Resolver
import SolanaSwift
import SwiftyUserDefaults
import Combine

// MARK: - TransactionInfo

struct SendViaLinkTransactionInfo: Codable {
    let amount: Double
    let amountInFiat: Double
    let token: Token
    let seed: String
}

// MARK: - Protocols

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
    private let locker = NSLock()
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
            guard let userPubkey = self?.userPubkey,
                  let newValue = transactions.newValue?[userPubkey]
            else { return }
            self?.transactionsSubject.send(newValue)
        }
    }
    
    // MARK: - Actions
    
    @discardableResult
    func save(transaction: SendViaLinkTransactionInfo) -> Bool {
        locker.lock(); defer { locker.unlock() }
        
        // get seeds
        var seeds = getTransactions()
        
        // assert that seeds has not already existed
        guard !seeds.contains(where: { $0.seed == transaction.seed }) else {
            return true
        }
        
        // append seed
        seeds.append(transaction)
        
        // save
        return save(seeds: seeds)
    }
    
    func remove(seed: String) -> Bool {
        locker.lock(); defer { locker.unlock() }
        
        // get seeds from keychain
        var seeds = getTransactions()
        
        // remove seed
        seeds.removeAll(where: { $0.seed == seed })
        
        // save
        return save(seeds: seeds)
    }
    
    func getTransactions() -> [SendViaLinkTransactionInfo] {
        locker.lock(); defer { locker.unlock() }
        
        guard let userPubkey else {
            return []
        }
        return Defaults.sendViaLinkTransactions[userPubkey] ?? []
    }
    
    private func save(seeds: [SendViaLinkTransactionInfo]) -> Bool {
        guard let userPubkey else {
            return false
        }
        Defaults.sendViaLinkTransactions[userPubkey] = seeds
        return true
    }
}
