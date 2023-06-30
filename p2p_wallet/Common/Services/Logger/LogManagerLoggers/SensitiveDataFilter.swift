import Foundation

protocol SensitiveDataFilter {
    var rules: [SensitiveDataFilterRule] { get }
    func map(string: String) -> String
    func map(data: [AnyHashable: AnyHashable]) -> [AnyHashable: AnyHashable]
}

/// Default sensitive data filter, consist of basic rules
class DefaultSensitiveDataFilter: SensitiveDataFilter {
    var rules: [SensitiveDataFilterRule] = [PrivateKeySensitiveDataFilterRule()]

    func map(string: String) -> String {
        var ret = string
        rules.forEach { rule in
            ret = rule.map(ret)
        }
        return ret
    }

    func map(data: [AnyHashable: AnyHashable]) -> [AnyHashable: AnyHashable] {
        var newData = data
        data.keys.forEach { key in
            if let value = data[key] as? String {
                newData[key] = self.map(string: value)
            }
        }
        return newData
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
            guard let regex = try? NSRegularExpression(pattern: reg, options: NSRegularExpression.Options.caseInsensitive) else {
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
