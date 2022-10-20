import SwiftUI
import KeyAppUI

struct SolendPlaceholderView: View {
    let texts: [String] = [
        L10n.depositYourCrypto,
        L10n.earnUpToOn("6%", "USD"),
        L10n.convenientAndFlexible,
        L10n.withdrawRewardsOrFundsAtAnyTime
    ]
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 24) {
                    Image(uiImage: .solendPlaceholder)
                        .padding(.top, 24)
                    Group {
                        VStack(spacing: 10) {
                            ForEach(texts, id: \.self) { text in
                                HStack(spacing: 8) {
                                    Text("•")
                                        .apply(style: .text2)
                                    Text(text)
                                        .apply(style: .text2)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        Button {} label: {
                            TextButtonView(
                                title: L10n.comingSoon + "...",
                                style: .third,
                                size: .large
                            ) { }
                                .disabled(true)
                        }
                        .frame(height: 56)
                        .padding(.bottom, 24)
                    }
                        .padding(.horizontal, 24)
                }
                .background(Color(Asset.Colors.smoke.color))
                .cornerRadius(20)
                .padding(20)

                Spacer()
            }
        }
            .navigationBarTitle(L10n.earnOnYourFunds, displayMode: .large)
    }
}
