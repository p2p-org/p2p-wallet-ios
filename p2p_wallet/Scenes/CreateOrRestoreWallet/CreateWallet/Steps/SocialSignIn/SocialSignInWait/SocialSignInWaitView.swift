import SwiftUI
import KeyAppUI

struct SocialSignInWaitView: View {
    @ObservedObject var viewModel: SocialSignInWaitViewModel

    private let mainColor = Color(Asset.Colors.night.color)
    private let animationSize = CGSize(width: 272, height: 204)

    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                LottieView(lottieFile: "walletAnimation", loopMode: .loop)
                    .scaledToFill()
                    .frame(width: animationSize.width, height: animationSize.height)

                Text(viewModel.title)
                    .apply(style: .largeTitle)
                    .foregroundColor(mainColor)
                    .padding(.top, 36)
                    .transition(.opacity.animation(.linear))

                ZStack {
                    IndeterminateProgressBar(indicatorColor: mainColor)
                        .frame(width: 113)
                        .opacity(viewModel.isProgressVisible ? 1 : 0)
                    Text(viewModel.subtitle)
                        .apply(style: .title3)
                        .foregroundColor(mainColor)
                        .opacity(viewModel.isProgressVisible ? 0 : 1)
                }
                .transition(.opacity.animation(.linear))
                .padding(.top, 16)
            }
            .edgesIgnoringSafeArea(.top)
            .padding(.horizontal, 20)
            .padding(.bottom, animationSize.height / 2)
        }
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
