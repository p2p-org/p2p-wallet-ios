import BigInt
import Foundation

/// Factory class for automatically creating formatter.
public enum CryptoFormatterFactory {
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
    /// Default string in case when parsing in not possible.
    public let defaultValue: String
    
    /// Appended prefix of output
    public let prefix: String
    
    /// Hide symbol in output
    public let hideSymbol: Bool
    
    /// Max number of digit.
    public let maxDigits: Int?

    public init(defaultValue: String = "", prefix: String = "", hideSymbol: Bool = false, maxDigits: Int? = nil) {
        self.defaultValue = defaultValue
        self.prefix = prefix
        self.hideSymbol = hideSymbol
        self.maxDigits = maxDigits

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

    // MARK: - Private

    private func formattedValue(for obj: Any?) -> String? {
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
            formatter.roundingMode = .down
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

/// Representation of crypto numbers
public enum CryptoFormatterStyle {
    /// Short representation of crypto numbers, e.g. limited fraction digits
    case short

    /// Full representation of crypto numbers
    case long
}

/// Crypto formatter for ETH-like tokens
public final class ETHCryptoFormatter: CryptoFormatter {
    let style: CryptoFormatterStyle

    init(style: CryptoFormatterStyle) {
        self.style = style

        switch style {
        case .long:
            super.init()
        case .short:
            super.init(maxDigits: 8)
        }
    }

    override public func string(for obj: Any?) -> String? {
        super.string(for: obj)
    }
}

/// Helper protocol for quickly converting to ``CryptoAmount``.
public protocol CryptoAmountConvertible {
    var asCryptoAmount: CryptoAmount { get }
}
