import BigInt
import Foundation

/// Helper protocol for quickly converting to ``CryptoAmount``.
public protocol CryptoAmountConvertible {
    var asCryptoAmount: CryptoAmount { get }
}

public enum CryptoFormatterStyle {
    /// Short representation of crypto numbers, e.g. limited fraction digits
    case short
    case long
}

public class CryptoFormatterFactory {
    public static func formatter(with token: SomeToken, style: CryptoFormatterStyle = .long) -> CryptoFormatter {
        if token.tokenPrimaryKey == "native-ethereum" && token.decimals == 18 {
            return ETHCryptoFormatter(style: style)
        } else {
            return CryptoFormatter()
        }
    }
}

/// A general string-formatter for crypto
public class CryptoFormatter: Formatter {
    public let defaultValue: String
    public let prefix: String
    public let hideSymbol: Bool

    public init(defaultValue: String = "", prefix: String = "", hideSymbol: Bool = false) {
        self.defaultValue = defaultValue
        self.prefix = prefix
        self.hideSymbol = hideSymbol
        super.init()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError()
    }

    public func string(amount: CryptoAmountConvertible) -> String {
        formattedValue(for: amount.asCryptoAmount) ?? defaultValue
    }

    public func string(amount: CryptoAmount) -> String {
        formattedValue(for: amount) ?? defaultValue
    }

    override public func string(for obj: Any?) -> String? {
        formattedValue(for: obj)
    }

    public func string(for obj: Any?, maxDigits: Int? = nil) -> String? {
        formattedValue(for: obj, maxDigits: maxDigits)
    }

    // MARK: - Private

    private func formattedValue(for obj: Any?, maxDigits: Int? = nil) -> String? {
        let amount: CryptoAmount?

        if let obj = obj as? CryptoAmount {
            amount = obj
        } else if let obj = obj as? CryptoAmountConvertible {
            amount = obj.asCryptoAmount
        } else {
            amount = nil
        }

        guard let amount else { return nil }

        let formatter = NumberFormatter()
        formatter.groupingSize = 3
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = " "
        if let maxDigits {
            formatter.maximumFractionDigits = maxDigits
        } else {
            formatter.maximumFractionDigits = Int(amount.token.decimals)
        }

        let convertedValue = Decimal(string: String(amount.amount))
        guard var formattedAmount = formatter.string(for: convertedValue) else {
            return nil
        }

        if !prefix.isEmpty {
            formattedAmount = prefix + " \(formattedAmount)"
        }

        if hideSymbol {
            return formattedAmount
        } else {
            return "\(formattedAmount) \(amount.token.symbol)"
        }
    }
}

/// Crypto formatter for ETH-like tokens
public final class ETHCryptoFormatter: CryptoFormatter {
    let style: CryptoFormatterStyle

    init(style: CryptoFormatterStyle) {
        self.style = style
        super.init()
    }

    public override func string(for obj: Any?) -> String? {
        super.string(for: obj, maxDigits: style == .short ? 8 : nil)
    }
}
