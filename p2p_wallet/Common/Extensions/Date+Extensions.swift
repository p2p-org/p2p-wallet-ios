import Foundation

extension Date {
    func string(withFormat format: String, locale: Locale = Locale.shared) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
