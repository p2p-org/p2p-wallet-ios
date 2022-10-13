import KeyAppUI
import SwiftUI

struct HomeBuyNotificationView: View {
    let sourceSymbol: String
    let destinationSymbol: String
    let buttonTapped: (() -> Void)?

    var body: some View {
        HomeBuyNotification(
            title: L10n.transactionDetails,
            buttonTitle: L10n.buy + " USDC",
            buttonTapped: buttonTapped
        ) {
            VStack(alignment: .center, spacing: 24) {
                Text(L10n.youReGoungToBuy + " \(destinationSymbol)")
                    .fontWeight(.bold)
                    .apply(style: .title1)
                    .multilineTextAlignment(.center)
                Text(L10n.youFirstNeedToBuyAndThenSwapForOnTheMainPage(sourceSymbol, destinationSymbol))
                    .apply(style: .title3)
                    .multilineTextAlignment(.center)
                HomeBuyTips(sourceSymbol: sourceSymbol, destinationSymbol: destinationSymbol)
            }
        }
    }
}

struct HomeBuyNotification<Content: View>: View {
    let child: Content
    let buttonTapped: (() -> Void)?
    let title: String
    let buttonTitle: String

    init(
        title: String,
        buttonTitle: String,
        buttonTapped: (() -> Void)? = nil,
        @ViewBuilder child: () -> Content
    ) {
        self.child = child()
        self.buttonTapped = buttonTapped
        self.title = title
        self.buttonTitle = buttonTitle
    }

    var body: some View {
        VStack {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.top, 6)

            Text(title)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .padding(.top, 11)

            Spacer()

            VStack {
                child.padding(.top, 21)
                Spacer()
                Button(
                    action: {
                        buttonTapped?()
                    },
                    label: {
                        Text(buttonTitle)
                            .foregroundColor(Color(Asset.Colors.lime.color))
                            .font(uiFont: .font(of: .text2, weight: .bold))
                            .frame(height: 58)
                            .frame(maxWidth: .infinity)
                            .background(Color(Asset.Colors.night.color))
                            .cornerRadius(12)
                            .padding(.horizontal, 2)
                            .padding(.bottom, 16)
                    }
                )
            }.padding(.horizontal, 24)
        }
    }
}

struct HomeBuyTips: View {
    let sourceSymbol: String
    let destinationSymbol: String

    var body: some View {
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
                    .frame(width: 1, height: 34)

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
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.buyingAsTheBaseCurrency(sourceSymbol))
                        .apply(style: .text1)
                        .foregroundColor(Color(Asset.Colors.night.color))

                    Text(L10n.purchasingOnTheMoonpaySWebsite)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.exchanging(sourceSymbol, destinationSymbol))
                        .apply(style: .text1)
                        .foregroundColor(Color(Asset.Colors.night.color))
                    Text(L10n.thereWouldBeNoAdditionalCosts)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
            }

            Spacer()
        }
        .padding(.all, 20)
        .background(Color(Asset.Colors.smoke.color))
        .cornerRadius(20)
    }
}
