import SwiftUI
import KeyAppUI

struct SendInputFeePromptView: View {

    @ObservedObject private var viewModel: SendInputFeePromptViewModel

    private let mainColor = Asset.Colors.night.color

    init(viewModel: SendInputFeePromptViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ColoredBackground {
            VStack(alignment: .center, spacing: 0) {
                Image(uiImage: .fee)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300)
                    .padding(.horizontal, 16)

                Spacer()

                Text(viewModel.title)
                    .font(uiFont: .font(of: .title1, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(mainColor))
                    .padding(.horizontal, 32)
                    .accessibilityIdentifier("SendInputFeePromptView.title")

                Text(viewModel.description)
                    .apply(style: .text1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(mainColor))
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("SendInputFeePromptView.description")

                Spacer()

                if viewModel.isChooseTokenAvailable {
                    multipleTokenActions
                } else {
                    singleTokenAction
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .padding(.top, 60)
            .if(viewModel.isChooseTokenAvailable) { view in
                view
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
    }

    var multipleTokenActions: some View {
        BottomActionContainer {
            VStack(spacing: 12) {
                NewTextButton(
                    title: viewModel.continueTitle,
                    style: .inverted,
                    action: viewModel.close.send
                )
                .accessibility(identifier: "SendInputFeePromptView.multipleTokenActions.top")

                NewTextButton(
                    title: L10n.switchToAnotherToken,
                    style: .ghostLime,
                    action: viewModel.chooseToken.send
                )
                .accessibility(identifier: "SendInputFeePromptView.multipleTokenActions.bottom")
            }
        }
    }

    var singleTokenAction: some View {
        NewTextButton(
            title: L10n.ok.uppercased(),
            style: .primaryWhite,
            action: viewModel.close.send
        )
        .accessibility(identifier: "SendInputFeePromptView.singleTokenAction")
    }
}

struct SendInputFeePromptView_Previews: PreviewProvider {
    static var previews: some View {
        SendInputFeePromptView(
            viewModel: SendInputFeePromptViewModel(
                feeToken: .init(token: .usdc),
                feeInToken: .zero,
                availableFeeTokens: []
            )
        )
    }
}
