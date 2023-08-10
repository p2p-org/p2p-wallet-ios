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
    public var flagEmoji: String?
    public var isStrigaAllowed: Bool
    public var isMoonpayAllowed: Bool

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.alpha2 = try container.decode(String.self, forKey: .alpha2)
        self.alpha3 = try container.decode(String.self, forKey: .alpha3)
        self.flagEmoji = try container.decodeIfPresent(String.self, forKey: .flagEmoji)?.stringByDecodingHTMLEntities
        self.isStrigaAllowed = try container.decode(Bool.self, forKey: .isStrigaAllowed)
        self.isMoonpayAllowed = try container.decode(Bool.self, forKey: .isMoonpayAllowed)
    }
}

public typealias Countries = [Country]


private extension String {
    /// Returns a new string made by replacing in the `String`
    /// all HTML character entity references with the corresponding
    /// character.
    var stringByDecodingHTMLEntities : String {

        // ===== Utility functions =====

        // Convert the number in the string to the corresponding
        // Unicode character, e.g.
        //    decodeNumeric("64", 10)   --> "@"
        //    decodeNumeric("20ac", 16) --> "€"
        func decodeNumeric(_ string : Substring, base : Int) -> Character? {
            guard let code = UInt32(string, radix: base),
                let uniScalar = UnicodeScalar(code) else { return nil }
            return Character(uniScalar)
        }

        // Decode the HTML character entity to the corresponding
        // Unicode character, return `nil` for invalid input.
        //     decode("&#64;")    --> "@"
        //     decode("&#x20ac;") --> "€"
        //     decode("&lt;")     --> "<"
        //     decode("&foo;")    --> nil
        func decode(_ entity : Substring) -> Character? {

            if entity.hasPrefix("&#x") || entity.hasPrefix("&#X") {
                return decodeNumeric(entity.dropFirst(3).dropLast(), base: 16)
            } else if entity.hasPrefix("&#") {
                return decodeNumeric(entity.dropFirst(2).dropLast(), base: 10)
            } else {
                return characterEntities[entity]
            }
        }

        // ===== Method starts here =====

        var result = ""
        var position = startIndex

        // Find the next '&' and copy the characters preceding it to `result`:
        while let ampRange = self[position...].range(of: "&") {
            result.append(contentsOf: self[position ..< ampRange.lowerBound])
            position = ampRange.lowerBound

            // Find the next ';' and copy everything from '&' to ';' into `entity`
            guard let semiRange = self[position...].range(of: ";") else {
                // No matching ';'.
                break
            }
            let entity = self[position ..< semiRange.upperBound]
            position = semiRange.upperBound

            if let decoded = decode(entity) {
                // Replace by decoded character:
                result.append(decoded)
            } else {
                // Invalid entity, copy verbatim:
                result.append(contentsOf: entity)
            }
        }
        // Copy remaining characters to `result`:
        result.append(contentsOf: self[position...])
        return result
    }
}

private let characterEntities : [ Substring : Character ] = [
    // XML predefined entities:
    "&quot;"    : "\"",
    "&amp;"     : "&",
    "&apos;"    : "'",
    "&lt;"      : "<",
    "&gt;"      : ">",

    // HTML character entity references:
    "&nbsp;"    : "\u{00a0}",
    // ...
    "&diams;"   : "♦",
]
