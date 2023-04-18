import AnalyticsManager
import SwiftUI
import KeyAppUI
import Resolver

struct SendCreateLinkView: View {

    private let mainColor = Color(Asset.Colors.night.color)
    private let subColor = Color(Asset.Colors.silver.color)
    private let animationSize = CGSize(width: 272, height: 204)

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                LottieView(lottieFile: "sendViaLinkAnimation", loopMode: .loop)
                    .scaledToFill()
                    .frame(width: animationSize.width, height: animationSize.height)
                    .padding(.bottom, 36)

                Text(L10n.creatingYourOneTimeLink)
                    .apply(style: .largeTitle)
                    .foregroundColor(mainColor)
                    .transition(.opacity.animation(.linear))
                    .padding(.bottom, 76)

                IndeterminateProgressBar(indicatorColor: mainColor)
                    .frame(width: 113)
            }
            .edgesIgnoringSafeArea(.top)
            .padding(.horizontal, 20)
            .padding(.bottom, animationSize.height / 2)
        }
        .onAppear {
            Resolver.resolve(AnalyticsManager.self).log(event: .sendCreatingLinkProcessScreenOpen)
        }
    }
}

struct SendCreateLinkView_Previews: PreviewProvider {
    static var previews: some View {
        SendCreateLinkView()
    }
}
