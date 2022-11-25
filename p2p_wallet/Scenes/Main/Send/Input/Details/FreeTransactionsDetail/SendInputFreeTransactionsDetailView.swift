import SwiftUI
import KeyAppUI

struct SendInputFreeTransactionsDetailView: View {

    let actionButtonPressed: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.vertical, 6)
            Spacer()
            VStack(spacing: 32) {
                Image(uiImage: .startThree)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300)

                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .frame(width: 48, height: 48)
                            .foregroundColor(Color(Asset.Colors.smoke.color))
                        Image(uiImage: .lightningFilled)
                            .renderingMode(.template)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .frame(width: 20, height: 20)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(L10n.enjoyFreeTransactions)!")
                            .font(uiFont: .font(of: .text1, weight: .bold))
                            .foregroundColor(Color(Asset.Colors.night.color))
                        Text(L10n.onTheSolanaNetworkTheFirst100TransactionsInADayArePaidByKeyApp)
                            .apply(style: .label1)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    }
                }

                TextButtonView(
                    title: "\(L10n.awesome) 👍",
                    style: .primaryWhite,
                    size: .large,
                    onPressed: actionButtonPressed
                )
                .frame(height: TextButton.Size.large.height)
                
            }
            .padding(.horizontal, 16)
        }
    }
}

struct SendInputFreeTransactionsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SendInputFreeTransactionsDetailView(actionButtonPressed: {})
    }
}
