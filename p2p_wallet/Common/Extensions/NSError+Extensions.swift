import Foundation

extension NSError {
    var isNetworkConnectionError: Bool {
        code == NSURLErrorNetworkConnectionLost || code == NSURLErrorNotConnectedToInternet || code ==
            NSURLErrorDataNotAllowed
    }
}
