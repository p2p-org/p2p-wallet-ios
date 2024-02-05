import SwiftUI
import WebKit

struct ReferralWebView: UIViewRepresentable {
    private let url: URL
    private let wkWebView: WKWebView

    init(webView: WKWebView, link: URL) {
        wkWebView = webView
        url = link
    }

    func makeUIView(context _: Context) -> WKWebView {
        wkWebView
    }

    func updateUIView(_: WKWebView, context _: Context) {
        let request = URLRequest(url: url)
        wkWebView.load(request)
    }
}
