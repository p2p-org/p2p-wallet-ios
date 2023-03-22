import Foundation
import Resolver
import SolanaSwift
import SwiftyUserDefaults
import Combine

// MARK: - TransactionInfo

struct SendViaLinkTransactionInfo: Codable, Identifiable {
    let amount: Double
    let amountInFiat: Double
    let token: Token
    let seed: String
    let timestamp: Date?
    
    var id: String {
        seed
    }
}

#if DEBUG
extension Array where Element == SendViaLinkTransactionInfo {
    static var mocked: Self {
        [
            .init(
                amount: 10,
                amountInFiat: 20,
                token: .nativeSolana,
                seed: .generateSendViaLinkSeed(),
                timestamp: nil // Today
            ),
            .init(
                amount: 1,
                amountInFiat: 0.99,
                token: .usdc,
                seed: .generateSendViaLinkSeed(),
                timestamp: Date()
                    .addingTimeInterval(-60*60*24*1) // This time yesterday
            ),
            .init(
                amount: 1,
                amountInFiat: 1.01,
                token: .usdt,
                seed: .generateSendViaLinkSeed(),
                timestamp: Date()
                    .addingTimeInterval(-60*60*24*2) // 2 days ago
            ),
            .init(
                amount: 100,
                amountInFiat: 1,
                token: .srm,
                seed: .generateSendViaLinkSeed(),
                timestamp: Date()
                    .addingTimeInterval(-60*60*24*1) // 3 days ago
            )
        ]
    }
}
#endif

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
        transactions.append(transaction)
        
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
