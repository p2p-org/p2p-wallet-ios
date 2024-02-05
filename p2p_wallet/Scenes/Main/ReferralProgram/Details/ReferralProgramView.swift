import SwiftUI

struct ReferralProgramView: View {
    @ObservedObject private var viewModel: ReferralProgramViewModel

    init(viewModel: ReferralProgramViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ColoredBackground(
            {
                ReferralWebView(
                    webView: viewModel.webView,
                    link: viewModel.link
                )
                .ignoresSafeArea(edges: .bottom)
            },
            color: Color(uiColor: UIColor(resource: .f2F5Fa))
        )
        .navigationTitle(L10n.referralProgram)
        .navigationBarTitleDisplayMode(.inline)
    }
}
