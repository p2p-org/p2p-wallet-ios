import Combine
import Foundation
import WebKit

final class ReferralProgramViewModel: BaseViewModel, ObservableObject {
    let link: URL
    let bridge: ReferralJSBridge
    let webView: WKWebView

    let openShare = PassthroughSubject<String, Never>()

    override init() {
        let wkWebView = ReferralProgramViewModel.buildWebView()
        webView = wkWebView
        bridge = ReferralJSBridge(webView: wkWebView)
        link = URL(string: GlobalAppState.shared.newReferralProgramEndpoint) ??
            URL(string: String.secretConfig("REFERRAL_PROGRAM_ENDPOINT")!)!
        super.init()

        bridge.inject()

        bridge.sharePublisher
            .sink(receiveValue: { [weak self] value in
                self?.openShare.send(value)
            })
            .store(in: &subscriptions)
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
