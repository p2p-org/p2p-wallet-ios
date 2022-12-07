import Combine
import Foundation

public enum SellDataServiceStatus {
    case initialized
    case updating
    case ready
    case error
}

public protocol SellDataService {
    associatedtype Provider: SellDataServiceProvider
    var status: AnyPublisher<SellDataServiceStatus, Never> { get }
    var lastUpdateDate: AnyPublisher<Date, Never> { get }

    /// Request for pendings, rates, min amounts
    func update() async throws

    /// Return incomplete transactions
    func incompleteTransactions() async throws -> [Provider.Transaction]
    /// Return transaction by  id
    func transaction(id: String) async throws -> Provider.Transaction
    /// Weather service available
    func isAvailable() async throws -> Bool
}

public protocol SellActionService {
    func calculateRates() async throws -> Double
    func providerSellURL() -> URL
    func saveTransaction() async throws
    func deleteTransaction() async throws
}

//public protocol StateMachine<State, Action> {
//    associatedtype State
//    associatedtype Action
//
//    func accept(action: Action) async -> State
//}
//
//enum SellState {
//    case loading
//    case pendingRequests
//    case createRequest
//    case request
//}
//
//enum SellAction {
//    case calculate(solAmount: Double)
//    case calculate(fiatAmount: Double)
//}
//
//enum SellServices {
//
//}
//
//public actor SellInputStateMachine: StateMachine {
//    // Associated types
//    public typealias Action = SellAction
//    public typealias Services = SellServices
//    public typealias State = SellState
//
//    // Container
//    private nonisolated let stateSubject: CurrentValueSubject<State, Never>
//
//    // Variables
//    public nonisolated var statePublisher: AnyPublisher<State, Never> {
//        stateSubject.eraseToAnyPublisher()
//    }
//    public nonisolated var currentState: State { stateSubject.value }
//
//    // Constants
//    public nonisolated let services: Services
//
//    public init(initialState: State, services: Services) {
//        stateSubject = .init(initialState)
//        self.services = services
//    }
//
//    public func accept(action: SellAction) async -> State {
//        return reduce(currentState, action)
//    }
//
//    private func reduce(_ state: State, _ action: Action) -> State {
//        return .loading
//    }
//}
