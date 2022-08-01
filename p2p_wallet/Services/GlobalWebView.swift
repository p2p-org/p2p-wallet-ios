// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

// class WebviewReference {
//     let view: WKWebView
//
//     init(view: WKWebView) { self.view = view }
//
//     deinit {
//         print("Deinit webview")
//         view.removeFromSuperview()
//     }
// }

class GlobalWebView {
    static func requestWebView() -> WKWebView {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("[WebCacheCleaner] All cookies deleted")

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("[WebCacheCleaner] Record \(record) deleted")
            }
        }

        let webView = WKWebView()
        UIApplication.shared.windows.first?.addSubview(webView)
        return webView
    }
}
