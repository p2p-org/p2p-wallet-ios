import SwiftUI

struct MoonpayInfoView: View {
    var actionButtonPressed: ((Bool) -> Void)?
    @State var isChecked = false

    var body: some View {
        VStack {
            Color(.rain)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.vertical, 6)
            Image(.moonpayLogo)
                .padding(.top, 18)
            Text(L10n.serviceIsNextStep)
                .fontWeight(.bold)
                .apply(style: .title3)

            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: 2) {
                    Text("1")
                        .fontWeight(.semibold)
                        .apply(style: .label1)
                        .foregroundColor(Color(.snow))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color(.night))
                        )

                    Rectangle()
                        .fill(Color(.mountain))
                        .frame(width: 1, height: 70)

                    Text("2")
                        .fontWeight(.semibold)
                        .apply(style: .label1)
                        .foregroundColor(Color(.night))
                        .frame(width: 24, height: 20)
                        .background(
                            Circle()
                                .stroke(Color(.mountain), lineWidth: 1.5)
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.youWillBeRedirectedToOurPaymentProvider)
                            .apply(style: .text1)
                            .foregroundColor(Color(.night))

                        Text(L10n.youWillNeedToEnterYourIBANAndPassKYC)
                            .apply(style: .text4)
                            .foregroundColor(Color(.mountain))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.transferSOLToOurPaymentProviderFromKeyApp)
                            .apply(style: .text1)
                            .foregroundColor(Color(.night))
                        Text(L10n.nobodyHasAccessToYourFundsSoYouNeedToExecuteTheTransactionCashOut)
                            .apply(style: .text4)
                            .foregroundColor(Color(.mountain))
                    }
                }
                .padding(.leading, 10)
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(Color(.smoke))
            .cornerRadius(20)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Button {
                isChecked.toggle()
            } label: {
                HStack(spacing: 15) {
                    CheckboxView(isChecked: $isChecked)
                    Text(L10n.donTShowMeAgain)
                        .apply(style: .text3)
                        .foregroundColor(Color(.night))
                    Spacer()
                }
                .padding(.horizontal, 35)
                .padding(.vertical, 15)
            }

            Spacer()

            TextButtonView(
                title: L10n.letSGo + "!",
                style: .primaryWhite,
                size: .large,
                onPressed: { actionButtonPressed?(isChecked) }
            )
            .frame(height: TextButton.Size.large.height)
            .padding(.bottom, 30)
            .padding(.horizontal, 16)
        }
    }
}

struct CheckboxView: View {
    @Binding var isChecked: Bool
    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            if isChecked {
                Image(.checkboxFill)
            } else {
                Image(.checkboxEmpty)
            }
        }
    }
}

struct MoonpayInfoView_Previews: PreviewProvider {
    static var previews: some View {
        MoonpayInfoView()
    }
}
