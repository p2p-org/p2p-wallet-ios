import Combine
import Foundation
import WebKit

final class ReferralProgramViewModel: BaseViewModel, ObservableObject {
    enum Constants {
        static let urlString = "https://referral-2ii.pages.dev"
    }

    let link: URL
    let bridge: ReferralJSBridge
    let webView: WKWebView

    override init() {
        let wkWebView = ReferralProgramViewModel.buildWebView()
        webView = wkWebView
        bridge = ReferralJSBridge(webView: wkWebView)
        link = URL(string: GlobalAppState.shared.newReferralProgramEndpoint) ?? URL(string: Constants.urlString)!
        super.init()

        bridge.inject()
    }

    private static func buildWebView() -> WKWebView {
        let userContentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        let preferences = WKPreferences()
        configuration.preferences = preferences
        let webView = WKWebView(frame: .zero, configuration: configuration)

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        return webView
    }
}
