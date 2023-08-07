import Foundation
import WebKit

/// The class is responsible for creating background web view.
class BackgroundWebViewManager {
    static func requestWebView() -> WKWebView {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }

        let webView = WKWebView()

        if #available(iOS 16.4, *) {
            if Environment.current == .debug {
                webView.isInspectable = true
            }
        }

        UIApplication.shared.windows.first?.addSubview(webView)
        return webView
    }
}
