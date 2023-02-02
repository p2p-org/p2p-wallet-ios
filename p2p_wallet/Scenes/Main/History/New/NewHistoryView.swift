//
//  NewHistoryView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import KeyAppUI
import Kingfisher
import SwiftUI

struct NewHistoryView: View {
    @ObservedObject var viewModel: NewHistoryViewModel

    var body: some View {
        VStack {
            TextField("Hello", text: .constant(""))
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.historyItems, id: \.id) { item in
                        NewHistoryItemView(item: item)
                    }
                }
            }
        }
    }
}

struct NewHistoryItemView: View {
    let item: any NewHistoryItem

    var titleColor: Color {
        switch item.status {
        case .success: return Color(Asset.Colors.night.color)
        case .failed: return Color(Asset.Colors.rose.color)
        }
    }
    
    var detailColor: Color {
        switch item.status {
        case .success:
            switch item.change {
            case .positive: return Color(Asset.Colors.mint.color)
            case .negative: return Color(Asset.Colors.night.color)
            }
        case .failed: return Color(Asset.Colors.rose.color)
        }
    }

    var body: some View {
        HStack {
            NewHistoryIconView(icon: item.icon)
            VStack(spacing: 4) {
                HStack(spacing: 5) {
                    if item.status == .failed {
                        Image(uiImage: .crossIcon)
                            .renderingMode(.template)
                            .foregroundColor(titleColor)
                    }
                    Text(item.title)
                        .foregroundColor(titleColor)
                        .fontWeight(.semibold)
                        .apply(style: .text2)
                    Spacer()
                    Text(item.detail)
                        .fontWeight(.semibold)
                        .apply(style: .text2)
                        .foregroundColor(detailColor)
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
}

struct NewHistoryIconView: View {
    private let size: CGFloat = 46

    let icon: NewHistoryItemIcon

    var body: some View {
        Group {
            switch icon {
            case let .single(url):
                KFImage
                    .url(url)

                    .setProcessor(
                        DownsamplingImageProcessor(size: .init(width: size*2, height: size*2))
                            |> RoundCornerImageProcessor(cornerRadius: size)
                    )
                    .resizable()
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
            case let .double(from, to):
                // TODO: Implement design
                KFImage(from)
            }
        }
        .frame(width: 46, height: 46)
    }
}

struct NewHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NewHistoryView(
            viewModel: .init(
                initialHistoryItem: [
                    BaseHistoryItem.send(),
                    BaseHistoryItem.failedSend(),
                    BaseHistoryItem.receive(),
                    BaseHistoryItem.send(),
                    BaseHistoryItem.send(),
                    BaseHistoryItem.send()
                ]
            )
        )
    }
}
