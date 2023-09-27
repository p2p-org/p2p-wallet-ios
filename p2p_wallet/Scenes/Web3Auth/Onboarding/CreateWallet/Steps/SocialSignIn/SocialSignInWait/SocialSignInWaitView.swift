import SwiftUI

struct SocialSignInWaitView: View {
    @ObservedObject var viewModel: SocialSignInWaitViewModel

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
