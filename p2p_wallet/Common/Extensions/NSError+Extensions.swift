import Foundation

extension NSError {
    var isNetworkConnectionError: Bool {
        [
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorDataNotAllowed,
            NSURLErrorCannotFindHost,
            NSURLErrorTimedOut,
        ]
        .contains(code)
    }
}
