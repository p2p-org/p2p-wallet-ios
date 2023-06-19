import KeyAppUI
import SwiftUI

struct SocialSignInWaitView: View {
    @ObservedObject var viewModel: SocialSignInWaitViewModel

    private let mainColor = Color(Asset.Colors.night.color)
    private let animationSize = CGSize(width: 272, height: 204)

    var body: some View {
        LoadingAnimationLayout(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            isProgressVisible: viewModel.isProgressVisible
        )
        .onAppear {
            viewModel.appeared.send()
        }
    }
}

struct SocialSignInWaitView_Previews: PreviewProvider {
    static var previews: some View {
        SocialSignInWaitView(viewModel: SocialSignInWaitViewModel(strategy: .create))
    }
}
