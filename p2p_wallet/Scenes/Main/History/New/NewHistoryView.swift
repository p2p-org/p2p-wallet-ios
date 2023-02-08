//
//  NewHistoryView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import KeyAppUI

import SwiftUI

struct NewHistoryView: View {
    @ObservedObject var viewModel: NewHistoryViewModel

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.sections) { (section: NewHistorySection) in
                        
                        Text(section.title)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .padding(.top, 24)
                            .padding(.bottom, 12)
                        
                        Color(Asset.Colors.snow.color)
                            .frame(height: 12)
                            .cornerRadius(radius: 16, corners: [.topLeft, .topRight])
                        ForEach(section.items, id: \.id) { (item: NewHistoryItem) in
                            Group {
                                switch item {
                                case let .rendable(rendableItem):
                                    NewHistoryItemView(item: rendableItem) { 
                                        viewModel.onTap(item: rendableItem)
                                    }
                                case .placeHolder:
                                    SwiftUI.EmptyView()
                                case let .button(_, title, action):
                                    TextButtonView(
                                        title: title,
                                        style: .second,
                                        size: .large,
                                        onPressed: action
                                    )
                                    .frame(height: TextButton.Size.large.height)
                                }
                            }
                            .background(Color(Asset.Colors.snow.color))
                        }
                        Color(Asset.Colors.snow.color)
                            .frame(height: 12)
                            .cornerRadius(radius: 16, corners: [.bottomLeft, .bottomRight])

                    }.padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(Asset.Colors.smoke.color))
    }
}

struct NewHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NewHistoryView(
            viewModel: .init(
                initialSections: [
                    .init(
                        title: "Today",
                        items: NewHistoryItemView_Previews.items.map { .rendable($0) }
                    ),
                    .init(
                        title: "Yesterday",
                        items: NewHistoryItemView_Previews.items.map { .rendable($0) }
                    )
                ]
            )
        )
    }
}
