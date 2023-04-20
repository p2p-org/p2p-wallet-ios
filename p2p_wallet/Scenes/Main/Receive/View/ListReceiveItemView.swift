import KeyAppUI
import SwiftUI

/// Receive List row cell
struct ListReceiveItemView: View {
    var item: ListReceiveItem

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(item.title)
                .foregroundColor(Color(Asset.Colors.night.color))
                .fontWeight(.semibold)
                .apply(style: .text3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(item.description)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .apply(style: .label1)
                .frame(maxWidth: 200)
                .multilineTextAlignment(.center)
                .frame(alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.top, item.showTopCorners ? 16 : 8)
        .padding(.bottom, item.showBottomCorners ? 16 : 8)
        .if(!item.isShort, transform: { view in
            view.frame(minHeight: 88)
        })
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: item.showTopCorners ? 16 : 0, corners: .topLeft)
        .cornerRadius(radius: item.showTopCorners ? 16 : 0, corners: .topRight)
        .cornerRadius(radius: item.showBottomCorners ? 16 : 0, corners: .bottomLeft)
        .cornerRadius(radius: item.showBottomCorners ? 16 : 0, corners: .bottomRight)
    }
}

struct ListReceiveItemView_Previews: PreviewProvider {
    static var previews: some View {
        ListReceiveItemView(item: .init(
            id: "1",
            title: "2",
            description: "0x9b7e823BC5578bcBeA74ba04F003167c590Aea0d",
            showTopCorners: true,
            showBottomCorners: true,
            isShort: false)
        )
    }
}
