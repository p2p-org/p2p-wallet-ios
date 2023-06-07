import Foundation

public protocol BankTransferRegistrationData: Codable {
    var firstName: String { get }
    var lastName: String { get }
    var email: String { get }
}
