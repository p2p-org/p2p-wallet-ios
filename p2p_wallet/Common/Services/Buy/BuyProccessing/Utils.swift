import Foundation

struct BuyProviderUtils {
    typealias Params = [String: String?]
}

extension BuyProviderUtils.Params {
    var query: String {
        filter {
            $1 != nil
        }.map { key, value in
            let value: String = value!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            return "\(key)=\(value)"
        }.joined(separator: "&")
    }
}
