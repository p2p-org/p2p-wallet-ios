import Foundation

extension NSError {
    var isNetworkConnectionError: Bool {
        code == NSURLErrorNetworkConnectionLost || code == NSURLErrorNotConnectedToInternet || code ==
            NSURLErrorDataNotAllowed
    }
}

extension Error {
    var isNetworkConnectionError: Bool {
        (self as NSError).isNetworkConnectionError
    }
}
