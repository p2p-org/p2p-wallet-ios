extension NSError {
    var isNetworkConnectionError: Bool {
        self.code == NSURLErrorNetworkConnectionLost || self.code == NSURLErrorNotConnectedToInternet || self.code == NSURLErrorDataNotAllowed
    }
}
