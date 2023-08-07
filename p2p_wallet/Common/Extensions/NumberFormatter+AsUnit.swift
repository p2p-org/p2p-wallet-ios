import Foundation

extension NumberFormatter {
    static func unit(for value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .down
        formatter.groupingSeparator = ""

        let value = abs(value)

        if value < 0.01 {
            return "0"
        } else if value >= 0.01 && value < 1 {
            formatter.maximumFractionDigits = 2
        } else if value >= 1 && value < 10000 {
            formatter.maximumFractionDigits = 0
        } else if value >= 10000 && value < 1_000_000 {
            formatter.multiplier = 0.001
            formatter.positiveSuffix = "k"
            formatter.maximumFractionDigits = 1
        } else if value >= 1_000_000 && value < 1_000_000_000 {
            formatter.multiplier = 0.000001
            formatter.positiveSuffix = "M"
            formatter.maximumFractionDigits = 0
        } else if value >= 1_000_000_000 {
            return "999M+"
        }

        return formatter.string(from: value as NSNumber) ?? "0"
    }
}
