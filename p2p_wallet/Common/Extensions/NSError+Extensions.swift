import Foundation

extension NSError {
    var isNetworkConnectionError: Bool {
        [
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorDataNotAllowed,
        ]
            .contains(code)
    }
}
