import KeyAppUI
import SwiftUI

/// Receive List row cell
struct ListReceiveItemView: View {
    var item: ListReceiveItem

    var body: some View {
        VStack(alignment: .center, spacing: item.isShort ? 4 : 7) {
            Text(item.title)
                .foregroundColor(Color(.night))
                .fontWeight(.semibold)
                .apply(style: .text3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(item.description)
                .foregroundColor(Color(.mountain))
                .apply(style: .label1)
                .frame(maxWidth: !item.isShort ? 200 : 300)
                .multilineTextAlignment(.center)
                .frame(alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.top, item.showTopCorners ? 16 : item.isShort ? 8 : 11)
        .padding(.bottom, item.showBottomCorners ? 16 : item.isShort ? 8 : 13)
        .if(!item.isShort, transform: { view in
            view.frame(minHeight: 90)
        })
        .background(Color(.snow))
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
