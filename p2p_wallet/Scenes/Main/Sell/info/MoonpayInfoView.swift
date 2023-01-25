import SwiftUI
import KeyAppUI

struct MoonpayInfoView: View {

    var actionButtonPressed: ((Bool) -> Void)?
    @State var isChecked = false

    var body: some View {
        VStack {
            Color(Asset.Colors.rain.color)
                   .frame(width: 31, height: 4)
                   .cornerRadius(2)
                   .padding(.vertical, 6)
            Image("moonpay-logo")
                .padding(.top, 18)
            Text("service is next step")
                .fontWeight(.bold)
                .apply(style: .title3)

            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: 2) {
                    Text("1")
                        .fontWeight(.semibold)
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color(Asset.Colors.night.color))
                        )

                    Rectangle()
                        .fill(Color(Asset.Colors.mountain.color))
                        .frame(width: 1, height: 70)

                    Text("2")
                        .fontWeight(.semibold)
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .frame(width: 24, height: 20)
                        .background(
                            Circle()
                                .stroke(Color(Asset.Colors.mountain.color), lineWidth: 1.5)
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You will be redirected to our payment provider")
                            .apply(style: .text1)
                            .foregroundColor(Color(Asset.Colors.night.color))

                        Text("You will need to enter your IBAN and pass KYC")
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transfer SOL to our payment provider from Key App")
                            .apply(style: .text1)
                            .foregroundColor(Color(Asset.Colors.night.color))
                        Text("Nobody has access to your funds, so you need to execute the transaction cash out")
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                    }
                }
                .padding(.leading, 10)
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(Color(Asset.Colors.smoke.color))
            .cornerRadius(20)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Button {
                isChecked.toggle()
            } label: {
                HStack(spacing: 15) {
                    CheckboxView(isChecked: $isChecked)
                    Text("Don’t show me again")
                        .apply(style: .text3)
                        .foregroundColor(Color(Asset.Colors.night.color))
                    Spacer()
                }
                .padding(.horizontal, 35)
                .padding(.vertical, 15)
            }

            Spacer()

            TextButtonView(
                title: "Let's go",
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
                Image("checkbox-fill")
            } else {
                Image("checkbox-empty")
            }
        }
    }
}

struct MoonpayInfoView_Previews: PreviewProvider {
    static var previews: some View {
        MoonpayInfoView()
    }
}
