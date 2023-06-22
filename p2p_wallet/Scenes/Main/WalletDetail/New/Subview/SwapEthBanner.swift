import KeyAppUI
import SwiftUI

struct SwapEthBanner: View {
    let text: String
    let action: () -> Void
    let close: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                Text(text)
                    .apply(style: .text1)
                    .foregroundColor(Color(Asset.Colors.night.color))
                Spacer()
                Button {
                    close()
                } label: {
                    Image(.closeIcon)
                }
            }
            TextButtonView(
                title: L10n.swap,
                style: .inverted,
                size: .large,
                onPressed: action
            )
            .frame(height: TextButton.Size.large.height)
        }
        .padding(.all, 16)
        .background(
            Image(.swapBannerBackground)
                .resizable()
        )
    }
}

struct SwapEthBanner_Previews: PreviewProvider {
    static var previews: some View {
        SwapEthBanner(text: "To send USDC to Ethereum network you have to swap it to USDCet") {} close: {}
    }
}
