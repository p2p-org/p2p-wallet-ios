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
                LottieView(lottieFile: "createWalletAnimation", loopMode: .loop)
                    .scaledToFill()
                    .frame(width: animationSize.width, height: animationSize.height)

                Text(viewModel.title)
                    .apply(style: .largeTitle)
                    .foregroundColor(mainColor)
                    .padding(.top, 36)
                    .transition(.opacity.animation(.linear))

                ZStack {
                    IndeterminateProgressBar()
                        .frame(width: 113, height: 4)
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
        SocialSignInWaitView(viewModel: SocialSignInWaitViewModel())
    }
}

struct IndeterminateProgressBar: View {
    @State private var offset: CGFloat = 0

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.1)
                    .foregroundColor(Color(Asset.Colors.night.color))

                Rectangle().frame(width: geometry.size.width / 2.5, height: geometry.size.height)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .cornerRadius(geometry.size.width / 2)
                    .offset(CGSize(width: offset, height: 0))
            }
            .cornerRadius(geometry.size.width / 2)
            .onReceive(timer) { _ in
                let progressWidth = geometry.size.width / 2.5
                withAnimation(.easeIn) {
                    offset += 15
                }
                if offset >= geometry.size.width + progressWidth {
                    offset = -progressWidth
                }
            }
        }
    }
}
