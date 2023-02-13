//
//  NewHistoryItemView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import KeyAppUI
import SwiftUI

struct NewHistoryItemView: View {
    let item: any NewHistoryRendableItem
    let onTap: () -> Void

    var titleColor: Color {
        switch item.status {
        case .success, .pending: return Color(Asset.Colors.night.color)
        case .failed: return Color(Asset.Colors.rose.color)
        }
    }

    var detailColor: Color {
        switch item.status {
        case .pending:
            return Color(Asset.Colors.night.color)
        case .success:
            switch item.change {
            case .positive: return Color(Asset.Colors.mint.color)
            case .negative: return Color(Asset.Colors.night.color)
            }
        case .failed: return Color(Asset.Colors.rose.color)
        }
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                NewHistoryIconView(icon: item.icon)
                VStack(spacing: 4) {
                    HStack(spacing: 5) {
                        switch item.status {
                        case .failed:
                            Image(uiImage: .crossIcon)
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(Asset.Colors.rose.color))
                                .frame(width: 14, height: 14)
                        case .pending:
                            Image(uiImage: .transactionIndicatorSellPending)
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(Asset.Colors.sun.color))
                                .frame(width: 18, height: 18)
                        case .success:
                            SwiftUI.EmptyView()
                        }
                        Text(item.title)
                            .foregroundColor(titleColor)
                            .fontWeight(.semibold)
                            .apply(style: .text2)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Text(item.detail)
                            .fontWeight(.semibold)
                            .apply(style: .text2)
                            .foregroundColor(detailColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text(item.subtitle)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .label1)
                        Spacer()
                        Text(item.subdetail)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .label1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
        }
        .buttonStyle(.borderless)
    }
}

struct NewHistoryItemView_Previews: PreviewProvider {
    static let items: [any NewHistoryRendableItem] = [
        MockedHistoryRendableItem.send(),
        MockedHistoryRendableItem.pendingSend(),
        MockedHistoryRendableItem.failedSend(),
        MockedHistoryRendableItem.receive(),
        MockedHistoryRendableItem.swap(),
        MockedHistoryRendableItem.mint(),
        MockedHistoryRendableItem.burn(),
        MockedHistoryRendableItem.stake(),
        MockedHistoryRendableItem.unstake(),
        MockedHistoryRendableItem.create(),
        MockedHistoryRendableItem.close(),
        MockedHistoryRendableItem.unknown()
    ]

    static var previews: some View {
        ScrollView {
            VStack {
                ForEach(items, id: \.id) { item in
                    NewHistoryItemView(item: item) {}
                }
            }
        }
    }
}
