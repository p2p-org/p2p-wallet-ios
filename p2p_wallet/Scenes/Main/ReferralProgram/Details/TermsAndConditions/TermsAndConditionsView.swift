import Foundation
import SwiftUI
import WebKit

struct TermsAndConditionsView: View {
    private let url: URL
    init(url: URL) {
        self.url = url
    }

    var body: some View {
        ColoredBackground(
            {
                ReferralWebView(webView: WKWebView(), link: url)
                    .ignoresSafeArea(edges: .bottom)
            },
            color: Color(uiColor: UIColor(resource: .f2F5Fa))
        )
        .navigationTitle(L10n.termsConditions)
        .navigationBarTitleDisplayMode(.inline)
    }
}
