import Foundation

public protocol RegistrationData: Codable {
    var firstName: String { get }
    var lastName: String { get }
    var email: String { get }
}
