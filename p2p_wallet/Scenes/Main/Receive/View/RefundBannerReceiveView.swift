import Foundation
import KeyAppUI
import SwiftUI

struct RefundBannerReceiveView: View {
    var item: RefundBannerReceiveItem

    var body: some View {
        HStack {
            Text(item.text)
                .foregroundColor(Color(Asset.Colors.night.color))
                .apply(style: .text3)
                .multilineTextAlignment(.leading)
            Spacer()
            Image(uiImage: .moneyDropsIllustration)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .background(Color(Asset.Colors.lightGrass.color))
        .cornerRadius(radius: 16, corners: .allCorners)
    }
}

struct RefundBannerReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        RefundBannerReceiveView(item: .init(text: "Some banner text"))
    }
}
