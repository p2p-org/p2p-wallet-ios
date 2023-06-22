import Foundation

extension Double {
    func toString(
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 3,
        showPlus: Bool = false,
        showMinus: Bool = true,
        groupingSeparator: String? = nil,
        autoSetMaximumFractionDigits: Bool = false,
        roundingMode: NumberFormatter.RoundingMode? = nil
    ) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSize = 3
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.currencyDecimalSeparator = "."
        formatter.groupingSeparator = " "
        formatter.minimumFractionDigits = minimumFractionDigits
        if let groupingSeparator = groupingSeparator {
            formatter.groupingSeparator = groupingSeparator
        }

        formatter.locale = Locale.current
        if showPlus {
            formatter.positivePrefix = formatter.plusSign
        }

        if !autoSetMaximumFractionDigits {
            formatter.maximumFractionDigits = maximumFractionDigits
        } else {
            if self > 1000 {
                formatter.maximumFractionDigits = 2
            } else if self > 100 {
                formatter.maximumFractionDigits = 4
            } else {
                formatter.maximumFractionDigits = 9
            }
        }

        if let roundingMode = roundingMode {
            formatter.roundingMode = roundingMode
        }

        let number = showMinus ? self : abs(self)
        return formatter.string(from: number as NSNumber) ?? "0"
    }
}
