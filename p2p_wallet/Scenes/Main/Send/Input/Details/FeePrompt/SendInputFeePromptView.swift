import SwiftUI
import KeyAppUI

struct SendInputFeePromptView: View {

    @ObservedObject private var viewModel: SendInputFeePromptViewModel

    private let mainColor = Asset.Colors.night.color

    init(viewModel: SendInputFeePromptViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .center, spacing: 0) {
                Image(uiImage: .sendFee)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300)

                Text(viewModel.title)
                    .font(uiFont: .font(of: .title1, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(mainColor))
                    .padding(.top, 56)

                Text(viewModel.description)
                    .apply(style: .text1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(mainColor))
                    .padding(.top, 16)

                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 32)

            if viewModel.isChooseTokenAvailable {
                VStack {
                    Spacer()
                    multipleTokenActions
                }
                .edgesIgnoringSafeArea(.bottom)
            } else {
                VStack {
                    Spacer()
                    singleTokenAction
                        .padding(.all, 16)
                }
            }
        }
    }

    var multipleTokenActions: some View {
        BottomActionContainer {
            VStack(spacing: 12) {
                TextButtonView(
                    title: viewModel.continueTitle,
                    style: .inverted,
                    size: .large,
                    onPressed: viewModel.close.send
                )
                .frame(height: 56)

                TextButtonView(
                    title: L10n.switchToAnotherToken,
                    style: .ghostLime,
                    size: .large,
                    onPressed: viewModel.chooseToken.send
                )
                .frame(height: 56)
            }
        }
    }

    var singleTokenAction: some View {
        TextButtonView(
            title: L10n.ok.uppercased(),
            style: .primaryWhite,
            size: .large,
            onPressed: viewModel.close.send
        )
        .frame(height: 56)
    }
}

struct SendInputFeePromptView_Previews: PreviewProvider {
    static var previews: some View {
        SendInputFeePromptView(viewModel: SendInputFeePromptViewModel(currentToken: .nativeSolana, feeToken: .usdc))
    }
}
