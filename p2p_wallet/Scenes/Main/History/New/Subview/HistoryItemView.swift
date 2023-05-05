//
//  NewHistoryItemView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import KeyAppUI
import SwiftUI

struct HistoryItemView: View {
    let item: any RendableListTransactionItem
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
            switch item.detail.0 {
            case .positive: return Color(Asset.Colors.mint.color)
            case .negative, .unchanged: return Color(Asset.Colors.night.color)
            }
        case .failed: return Color(Asset.Colors.rose.color)
        }
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                HistoryIconView(icon: item.icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .fontWeight(.semibold)
                        .apply(style: .text2)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
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
                        Text(item.subtitle)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .label1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if !item.detail.1.isEmpty {
                        Text(item.detail.1)
                            .fontWeight(.semibold)
                            .apply(style: .text2)
                            .foregroundColor(detailColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }

                    Text(item.subdetail)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .apply(style: .label1)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
        }
        .buttonStyle(.borderless)
    }
}

struct HistoryItemView_Previews: PreviewProvider {
    static let items: [any RendableListTransactionItem] = [
        MockedRendableListTransactionItem.send(),
        MockedRendableListTransactionItem.pendingSend(),
        MockedRendableListTransactionItem.failedSend(),
        MockedRendableListTransactionItem.receive(),
        MockedRendableListTransactionItem.swap(),
        MockedRendableListTransactionItem.mint(),
        MockedRendableListTransactionItem.burn(),
        MockedRendableListTransactionItem.stake(),
        MockedRendableListTransactionItem.unstake(),
        MockedRendableListTransactionItem.create(),
        MockedRendableListTransactionItem.close(),
        MockedRendableListTransactionItem.unknown()
    ]

    static var previews: some View {
        ScrollView {
            VStack {
                ForEach(items, id: \.id) { item in
                    HistoryItemView(item: item) {}
                }
            }
        }
    }
}
