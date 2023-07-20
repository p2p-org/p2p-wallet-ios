import Foundation

//Can't come up with a good name
public protocol WithdrawalInfoType: Equatable {
    var IBAN: String? { get }
    var BIC: String? { get }
    var receiver: String { get }
}

public protocol WithdrawProvider {
    associatedtype WithdrawalInfo: WithdrawalInfoType

    func withdrawalInfo() async throws -> WithdrawalInfo?
    func save(IBAN: String, BIC: String, receiver: String) async throws
}
