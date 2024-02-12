import SwiftUI

enum RecipientFormatter {
    private static let maxAddressLength = 6

    static func format(destination: String) -> String {
        var prefixCount = maxAddressLength

        if destination.hasPrefix("0x") {
            prefixCount += 2
        }

        if destination.count < maxAddressLength || destination.contains("@") {
            return destination
        } else {
            return "\(destination.prefix(prefixCount))...\(destination.suffix(maxAddressLength))"
        }
    }

    static func shortFormat(destination: String) -> String {
        if destination.count < maxAddressLength || destination.contains("@") {
            return destination
        } else {
            return "....\(destination.suffix(4))"
        }
    }

    static func longSignature(signature: String) -> String {
        if signature.count > 16 {
            return "\(signature.prefix(8))...\(signature.suffix(8))"
        } else {
            return signature
        }
    }

    static func signature(signature: String) -> String {
        "\(signature.prefix(4))...\(signature.suffix(4))"
    }

    static func username(name: String, domain: String) -> String {
        if domain == "key" {
            return "@\(name).\(domain)"
        } else if domain.isEmpty {
            return "\(name)"
        } else {
            return "\(name).\(domain)"
        }
    }
}
