//
//  NewHistoryView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import History
import KeyAppUI
import SwiftUI
import Resolver
import AnalyticsManager

struct NewHistoryView<Header: View>: View {
    @ObservedObject var viewModel: HistoryViewModel

    let header: Header

    var body: some View {
        ScrollView {
            header

            // Display error or empty state
            if
                viewModel.output.data.isEmpty,
                viewModel.output.status == .ready
            {
                if viewModel.output.error == nil {
                    HistoryEmptyView {
                        viewModel.actionSubject.send(.openBuy)
                    } secondaryAction: {
                        viewModel.actionSubject.send(.openReceive)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 38)
                } else {
                    ErrorView {
                        Task { try await viewModel.reload() }
                    }
                    .background(Color(Asset.Colors.snow.color))
                    .cornerRadius(radius: 16, corners: .allCorners)
                    .padding(.horizontal, 16)
                    .padding(.top, 38)
                }
            }

            // Render list
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.output.data) { (section: HistorySection) in
                    Text(section.title)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .padding(.top, viewModel.output.data.first == section ? 0 : 24)
                        .padding(.bottom, 12)

                    ForEach(section.items, id: \.id) { (item: NewHistoryItem) in
                        Group {
                            switch item {
                            case let .rendableTransaction(item):
                                HistoryItemView(item: item) {
                                    item.onTap?()
                                }
                            case let .rendableOffram(item):
                                HistoryOfframItemView(item: item) {
                                    item.onTap?()
                                }
                            case .placeHolder:
                                HistoryListSkeletonView()
                            case let .button(_, title, action):
                                TextButtonView(
                                    title: title,
                                    style: .second,
                                    size: .large,
                                    onPressed: action
                                )
                                .frame(height: TextButton.Size.large.height)
                                .padding(.all, 16)
                            case .fetch:
                                Rectangle()
                                    .fill(.clear)
                                    .contentShape(Rectangle())
                                    .onAppear { viewModel.fetch() }
                            }
                        }
                        .padding(.top, section.items.first == item ? 4 : 0)
                        .padding(.bottom, section.items.last == item ? 4 : 0)
                        .background(Color(Asset.Colors.snow.color))
                        .roundedList(
                            radius: 16,
                            isFirst: section.items.first == item,
                            isLast: section.items.last == item
                        )
                    }
                }.padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
        .customRefreshable { try? await viewModel.reload() }
        .background(Color(Asset.Colors.smoke.color))
        .onAppear {
            let analytic: AnalyticsManager = Resolver.resolve()
            analytic.log(event: KeyAppAnalyticsEvent.historyOpened)
            print("History opened")
            
            viewModel.fetch()
        }
    }
}

private extension View {
    func roundedList(radius: CGFloat, isFirst: Bool, isLast: Bool) -> some View {
        var corner: UIRectCorner = []

        if isFirst {
            corner = [.topLeft, .topRight]
        }

        if isLast {
            corner = [.bottomLeft, .bottomRight]
        }

        if isFirst && isLast {
            corner = .allCorners
        }

        if isFirst || isLast {
            return AnyView(
                self
                    .cornerRadius(
                        radius: radius,
                        corners: corner
                    )
            )
        } else {
            return AnyView(self)
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NewHistoryView(
            viewModel: .init(
                provider: MockKeyAppHistoryProvider()
            ),
            header: SwiftUI.EmptyView()
        )
    }
}
