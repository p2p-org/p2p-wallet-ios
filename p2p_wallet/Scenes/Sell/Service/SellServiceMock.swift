import Combine
import Foundation

class SellDataServiceMock: SellDataService {

    typealias Provider = MoonpaySellDataServiceProvider

    private let statusSubject = PassthroughSubject<SellDataServiceStatus, Never>()
    lazy var status: AnyPublisher<SellDataServiceStatus, Never> = {
        statusSubject.eraseToAnyPublisher()
    }()

    private let lastUpdateDateSubject = PassthroughSubject<Date, Never>()
    lazy var lastUpdateDate: AnyPublisher<Date, Never> = { lastUpdateDateSubject.eraseToAnyPublisher() }()

    func update() async throws {
        
    }

    func incompleteTransactions() async throws -> [Provider.Transaction] {
        []
    }

    func transaction(id: String) async throws -> Provider.Transaction {
        Provider.Transaction()
    }

    func isAvailable() async throws -> Bool {
        true
    }
}

class SellActionServiceMock: SellActionService {
    func calculateRates() async throws -> Double { 0 }
    func saveTransaction() async throws {}
    func deleteTransaction() async throws {}
}
