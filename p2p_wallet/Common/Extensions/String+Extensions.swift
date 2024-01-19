import Down
import FirebaseRemoteConfig
import Foundation
import UIKit

extension String {
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ... end])
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ..< end])
    }
}

extension Optional where Wrapped == String {
    public var orEmpty: String {
        self ?? ""
    }

    static func + (left: String?, right: String?) -> String {
        left.orEmpty + right.orEmpty
    }
}

extension String {
    var firstCharacter: String {
        String(prefix(1))
    }

    var uppercaseFirst: String {
        firstCharacter.uppercased() + String(dropFirst())
    }

    // swiftlint:disable swiftgen_strings
    func localized() -> String {
        NSLocalizedString(self, comment: "")
    }

    // swiftlint:enable swiftgen_strings

    func truncatingMiddle(numOfSymbolsRevealed: Int = 4, numOfSymbolsRevealedInSuffix: Int? = nil) -> String {
        if count <= numOfSymbolsRevealed + (numOfSymbolsRevealedInSuffix ?? numOfSymbolsRevealed) { return self }
        return prefix(numOfSymbolsRevealed) + "..." + suffix(numOfSymbolsRevealedInSuffix ?? numOfSymbolsRevealed)
    }

    static var nameServiceDomain: String {
        RemoteConfig.remoteConfig().usernameDomain ?? ".key"
    }

    static func secretConfig(_ key: String) -> String? {
        Bundle.main.infoDictionary?[key] as? String
    }
}

extension String {
    // TODO: Deprecate this getter. Use directly Double(string).
    var double: Double? {
        Double(self)
    }
}

// MARK: - Amount formatting

extension String {
    var fiatFormat: String {
        formatToMoneyFormat(decimalSeparator: ".", maxDecimals: 2)
    }

    var cryptoCurrencyFormat: String {
        formatToMoneyFormat(decimalSeparator: ".", maxDecimals: 9)
    }

    func formatToMoneyFormat(decimalSeparator: String, maxDecimals: UInt) -> String {
        var formatted = replacingOccurrences(of: ",", with: decimalSeparator)
            .replacingOccurrences(of: ".", with: decimalSeparator)
            .nonLetters(decimalSeparator: decimalSeparator)
        let components = formatted.components(separatedBy: decimalSeparator)
        let intPart = components[0]
        let withoutFirstZeros = intPart.count > 1 || intPart.isEmpty ? "\(Int(intPart) ?? 0)" : intPart
        if components.count >= 2 {
            let maxFormatted = components[1].prefix(Int(maxDecimals))
            formatted = "\(withoutFirstZeros)\(decimalSeparator)\(maxFormatted)"
            return formatted
        } else {
            return withoutFirstZeros
        }
    }

    private func nonLetters(decimalSeparator: String) -> String { filter("0123456789\(decimalSeparator)".contains) }
}

extension String {
    func separate(every: Int, with separator: String) -> String {
        String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0 ..< min($0 + every, Array(self).count)])
        }.joined(separator: separator))
    }
}

extension String {
    static var fakeTransactionSignaturePrefix: String {
        "<FakeTransactionSignature>"
    }

    static func fakeTransactionSignature(id: String) -> String {
        fakeTransactionSignaturePrefix + "<\(id)>"
    }
}

// MARK: - Flag

extension String {
    var asFlag: String? {
        let base: UInt32 = 127_397
        var s = ""
        unicodeScalars.forEach {
            s.unicodeScalars.append(UnicodeScalar(base + $0.value)!)
        }

        return String(stringLiteral: s)
    }
}
