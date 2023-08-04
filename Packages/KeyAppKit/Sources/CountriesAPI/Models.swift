import Foundation

// MARK: - Country
public struct Country: Codable, Hashable {
    public let name: String
    public let code: String
    public let dialCode: String
    public let emoji: String?
    public let alpha3Code: String

    public init(
        name: String,
        code: String,
        dialCode: String,
        emoji: String?,
        alpha3Code: String
    ) {
        self.name = name
        self.code = code
        self.dialCode = dialCode
        self.emoji = emoji
        self.alpha3Code = alpha3Code
    }

    enum CodingKeys: String, CodingKey {
        case name
        case code = "name_code"
        case dialCode = "phone_code"
        case emoji = "flag_emoji"
        case alpha3Code = "alpha3_code"
    }
}

public struct Region: Codable, Equatable, Hashable {
    public var name: String
    public let alpha2: String
    public let alpha3: String
    public let flagEmoji: String?
    public var isStrigaAllowed: Bool
    public var isMoonpayAllowed: Bool
}

public typealias Countries = [Country]
