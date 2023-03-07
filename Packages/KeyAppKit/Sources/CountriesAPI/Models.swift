import Foundation

// MARK: - Country
public struct Country: Codable, Hashable {
    public let name: String
    public let code: String
    public let dialCode: String
    public let emoji: String?

    public init (name: String, code: String, dialCode: String, emoji: String?) {
        self.name = name
        self.code = code
        self.dialCode = dialCode
        self.emoji = emoji
    }

    enum CodingKeys: String, CodingKey {
        case name
        case code = "name_code"
        case dialCode = "phone_code"
        case emoji = "flag_emoji"
    }
}

public typealias Countries = [Country]
