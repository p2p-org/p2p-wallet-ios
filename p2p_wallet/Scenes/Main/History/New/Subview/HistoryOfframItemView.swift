//
//  NewHistoryItemView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import SwiftUI

struct HistoryOfframItemView: View {
    let item: any RendableListOfframItem
    let onTap: () -> Void

    var primaryColor: Color {
        switch item.status {
        case .ready:
            return Color(.night)
        case .error:
            return Color(.rose)
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
                        .fill(Color(.rain))
                        .overlay(
                            Image(.transactionIndicatorSellPending)
                                .renderingMode(.template)
                                .foregroundColor(Color(.night))
                        )
                        .frame(width: 48, height: 48)

                case .error:
                    Circle()
                        .fill(Color(UIColor(red: 1, green: 0.863, blue: 0.914, alpha: 1)))
                        .overlay(
                            Image(.transactionIndicatorSellPending)
                                .renderingMode(.template)
                                .foregroundColor(Color(.rose))
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
                        .foregroundColor(Color(.mountain))
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
