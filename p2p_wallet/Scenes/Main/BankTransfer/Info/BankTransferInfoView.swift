import KeyAppUI
import SwiftUI

struct BankTransferInfoView: View {
    @ObservedObject var viewModel: BankTransferInfoViewModel

    var body: some View {
        ColoredBackground {
            VStack(spacing: 8) {
                list
                    .padding(.top, 8)

                Spacer()

                termsAndConditions
                    .padding(.bottom, 20)

                action
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
            .navigationBarItems(trailing: Button(
                action: viewModel.openHelp.send,
                label: {
                    Image(uiImage: Asset.MaterialIcon.helpOutline.image)
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
            ))
        }
    }
}

// MARK: - Subviews

private extension BankTransferInfoView {
    var list: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.items, id: \.id) { item in
                AnyRenderable(item: item)
            }
            .padding(.horizontal, 20)
        }
    }

    var termsAndConditions: some View {
        VStack(spacing: 2) {
            Text(L10n.byPressingTheButtonBelowYouAgree)
                .styled(color: Asset.Colors.night)
            HStack(spacing: 2) {
                Text(L10n.to.lowercased())
                    .styled(color: Asset.Colors.night)
                Text(L10n.terms)
                    .underline(color: Color(Asset.Colors.snow.color))
                    .styled(color: Asset.Colors.sky)
                    .onTapGesture(perform: viewModel.requestOpenTerms.send)
                Text(L10n.and)
                    .styled(color: Asset.Colors.night)
                Text(L10n.privacyPolicy)
                    .underline(color: Color(Asset.Colors.snow.color))
                    .styled(color: Asset.Colors.sky)
                    .onTapGesture(perform: viewModel.requestOpenPrivacyPolicy.send)
            }
        }
    }

    var action: NewTextButton {
        NewTextButton(
            title: L10n.continue,
            style: .primaryWhite,
            expandable: true,
            isLoading: viewModel.isLoading,
            trailing: Asset.MaterialIcon.arrowForward.image.withTintColor(Asset.Colors.lime.color),
            action: viewModel.requestContinue.send
        )
    }
}

struct BankTransferInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BankTransferInfoView(viewModel: .init())
    }
}

private extension Text {
    func styled(color: ColorAsset) -> some View {
        foregroundColor(Color(color.color))
            .font(.system(size: UIFont.fontSize(of: .label1)))
            .lineLimit(.none)
            .multilineTextAlignment(.center)
    }
}
