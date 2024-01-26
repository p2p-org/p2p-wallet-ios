import SwiftUI
import WebKit

struct ReferralProgramView: View {
    @ObservedObject private var viewModel: ReferralProgramViewModel

    init(viewModel: ReferralProgramViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ColoredBackground(
            {
                WebView(url: viewModel.link)
                    .ignoresSafeArea(edges: .bottom)
            },
            color: Color(uiColor: UIColor(resource: .f2F5Fa))
        )
        .navigationTitle(L10n.referralProgram)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context _: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context _: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
