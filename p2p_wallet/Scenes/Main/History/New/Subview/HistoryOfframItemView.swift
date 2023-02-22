//
//  NewHistoryItemView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import KeyAppUI
import SwiftUI

struct HistoryOfframItemView: View {
    let item: any RendableListOfframItem
    let onTap: () -> Void

    var primaryColor: Color {
        switch item.status {
        case .ready:
            return Color(Asset.Colors.night.color)
        case .error:
            return Color(Asset.Colors.rose.color)
        }
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                switch item.status {
                case .ready:
                    Circle()
                        .fill(Color(Asset.Colors.rain.color))
                        .overlay(
                            Image(uiImage: .transactionIndicatorSellPending)
                                .renderingMode(.template)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        )
                        .frame(width: 48, height: 48)

                case .error:
                    Circle()
                        .fill(Color(UIColor(red: 1, green: 0.863, blue: 0.914, alpha: 1)))
                        .overlay(
                            Image(uiImage: .transactionIndicatorSellPending)
                                .renderingMode(.template)
                                .foregroundColor(Color(Asset.Colors.rose.color))
                        )
                        .frame(width: 48, height: 48)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryColor)
                        .apply(style: .text3)

                    Text(item.subtitle)
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
                Spacer()
                Text(item.detail)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryColor)
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
        }
        .buttonStyle(.borderless)
    }
}

struct HistoryOfframItemView_Previews: PreviewProvider {
    static let items: [any RendableListOfframItem] = [
        MockRendableListOfframItem.error(),
        MockRendableListOfframItem.waiting(),
        MockRendableListOfframItem.processing(),
        MockRendableListOfframItem.done(),
    ]
    static var previews: some View {
        ScrollView {
            VStack {
                ForEach(items, id: \.id) { item in
                    HistoryOfframItemView(item: item) {}
                }
            }
        }
    }
}
