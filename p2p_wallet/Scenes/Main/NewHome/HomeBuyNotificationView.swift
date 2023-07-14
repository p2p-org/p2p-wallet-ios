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
                Text(L10n.youReGoingToBuy(destinationSymbol))
                    .fontWeight(.bold)
                    .apply(style: .title1)
                    .multilineTextAlignment(.center)
                Text(L10n.youFirstNeedToBuyAndThenSwapForOnTheMainPage(sourceSymbol, destinationSymbol))
                    .apply(style: .title3)
                    .minimumScaleFactor(0.5)
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
            Color(.rain)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.top, 6)

            Text(title)
                .foregroundColor(Color(.night))
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
                            .foregroundColor(Color(.lime))
                            .font(uiFont: .font(of: .text2, weight: .bold))
                            .frame(height: 58)
                            .frame(maxWidth: .infinity)
                            .background(Color(.night))
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
                    .foregroundColor(Color(.snow))
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color(.night))
                    )

                Rectangle()
                    .fill(Color(.mountain))
                    .frame(width: 1, height: 34)

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
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.buyingAsTheBaseCurrency(sourceSymbol))
                        .apply(style: .text1)
                        .minimumScaleFactor(0.9)
                        .foregroundColor(Color(.night))

                    Text(L10n.purchasingOnTheMoonpaySWebsite)
                        .apply(style: .text4)
                        .foregroundColor(Color(.mountain))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.exchanging(sourceSymbol, destinationSymbol))
                        .apply(style: .text1)
                        .foregroundColor(Color(.night))
                    Text(L10n.thereWouldBeNoAdditionalCosts)
                        .apply(style: .text4)
                        .foregroundColor(Color(.mountain))
                }
            }

            Spacer()
        }
        .padding(.all, 20)
        .background(Color(.smoke))
        .cornerRadius(20)
    }
}
