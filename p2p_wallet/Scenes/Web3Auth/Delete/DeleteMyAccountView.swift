import SwiftUI
import Resolver

struct DeleteMyAccountView: View {
    @State var slider: Bool = false
    @ObservedObject var walletSettings: WalletSettings = Resolver.resolve()

    var didRequestDelete: (() -> Void)?

    var body: some View {
        ExplainLayoutView {
            VStack {
                Image(.shield)
                Text(L10n.deleteMyAccount)
                    .fontWeight(.bold)
                    .apply(style: .title1)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
            }
        } content: {
            VStack {
                VStack(spacing: 12) {
                    ExplainText(text: L10n.whenYouDeleteYourAccountYouWillLoseAccessToYourFunds)
                    ExplainText(text: L10n.YouWillLoseAccessToTheFreeUsernameThatYouReceivedDuringRegistration.yourFriendsWillNotBeAbleToSendYouFundsUsingYourUsername)
                    ExplainText(text: L10n.youWillNotBeAbleToUseFreeTransactionsWithinTheSolanaNetworkWithKeyApp)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)

                Spacer()

                BottomActionContainer {
                    SliderButtonView(
                        title: L10n.yesDeleteIt,
                        image: .init(resource: .key),
                        style: .white,
                        isOn: $slider
                    )
                        .frame(height: 56)
                        .onChange(of: slider) { _ in
                            guard slider == true else { return }

                            walletSettings.deleteWeb3AuthRequest = Date()
                            didRequestDelete?()

                            slider = false
                        }

                }
            }
        } hint: {
            Text(L10n.makeSureYouUnderstand)
                .fontWeight(.semibold)
                .apply(style: .text1)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color(.rain), lineWidth: 1)
                )
                .offset(x: 0, y: 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.deleteMyAccount)
    }
}

struct DeleteMyAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeleteMyAccountView()
        }
    }
}
