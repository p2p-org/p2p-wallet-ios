import Foundation

public struct CreateNameAlertLoggerErrorMessage: Codable {
    let name: String
    let error: String

    enum CodingKeys: String, CodingKey {
        case name
        case error = "name_service_error"
    }
}
