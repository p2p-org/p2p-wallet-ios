import Foundation

/// Default sensitive data filter, consist of basic rules
class DefaultSensitiveDataFilter {
    var rules: [SensitiveDataFilterRule] = [PrivateKeySensitiveDataFilterRule()]

    func map(string: String) -> String {
        var ret = string
        rules.forEach { rule in
            ret = rule.map(ret)
        }
        return ret
    }
}

protocol SensitiveDataFilterRule {
    func map(_ string: String) -> String
}

/// Filters Ethereum and solana PKs
struct PrivateKeySensitiveDataFilterRule: SensitiveDataFilterRule {
    let placeholder = "<SensitiveDataFilter>"
    let regs = ["[1-9A-HJ-NP-Za-km-z]{87}", "0x[a-fA-F0-9]{64}"]

    func map(_ string: String) -> String {
        var str = string
        regs.forEach { reg in
            guard let regex = try? NSRegularExpression(
                pattern: reg,
                options: NSRegularExpression.Options.caseInsensitive
            ) else {
                return
            }
            let range = NSMakeRange(0, string.count)
            let modString = regex.stringByReplacingMatches(
                in: string, options: [], range: range, withTemplate: placeholder
            )
            str = modString
        }
        return str
    }
}
