//
//  ListRowReceiveCellView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import KeyAppUI
import SwiftUI

/// Receive List row cell
struct ListReceiveItemView: View {
    var item: ListReceiveItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .foregroundColor(Color(Asset.Colors.night.color))
                .fontWeight(.semibold)
                .apply(style: .text2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.description)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .apply(style: .text4)
                .multilineTextAlignment(.leading)
                .frame(alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, item.showTopCorners ? 16 : 8)
        .padding(.bottom, item.showBottomCorners ? 16 : 8)
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
            showBottomCorners: true)
        )
    }
}
