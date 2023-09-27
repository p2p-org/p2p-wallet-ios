import SwiftUI

private extension String {
    static let accessibilityTitleLabel = "SendLinkCreatedView.titleLabel"
    static let accessibilityCopyButton = "SendLinkCreatedView.copyButton"
    static let accessibilitySubtitleLabel = "SendLinkCreatedView.subtitleLabel"
}

struct SendLinkCreatedView: View {
    let viewModel: SendLinkCreatedViewModel

    var body: some View {
        VStack {
            // Close button
            HStack {
                Spacer()
                Button {
                    viewModel.closeClicked()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(8)
                }
                .foregroundColor(Color(.night))
            }

            Spacer()

            // Header
            Text(L10n.shareYourLinkToSendMoney)
                .apply(style: .largeTitle)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.night))
                .padding(.bottom, 24)
                .accessibilityIdentifier(.accessibilityTitleLabel)

            // Recipient
            RecipientCell(
                image: Image(.sendViaLinkCircleCompleted)
                    .castToAnyView(),
                title: viewModel.formatedAmount,
                subtitle: viewModel.link,
                trailingView: Button(
                    action: {
                        viewModel.copyClicked()
                    },
                    label: {
                        Image(.copyFill)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                )
                .accessibilityIdentifier(.accessibilityCopyButton)
                .castToAnyView()
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(Color(.snow))
            )
            .padding(.bottom, 28)

            // Subtitle
            Text(L10n.ifYouWantToGetYourMoneyBackJustOpenTheLinkByYourself)
                .apply(style: .text3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.mountain))
                .padding(.horizontal, 16)
                .accessibilityIdentifier(.accessibilitySubtitleLabel)

            Spacer()

            // Button
            TextButtonView(
                title: L10n.share,
                style: .primaryWhite,
                size: .large,
                onPressed: {
                    viewModel.shareClicked()
                }
            )
            .frame(height: TextButton.Size.large.height)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 20)
        .background(Color(.smoke).edgesIgnoringSafeArea(.vertical))
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct SendLinkCreatedView_Previews: PreviewProvider {
    static var previews: some View {
        SendLinkCreatedView(
            viewModel: SendLinkCreatedViewModel(
                link: "test.com/Ro8Andswf",
                formatedAmount: "7.12 SOL",
                intermediateAccountPubKey: ""
            )
        )
    }
}
