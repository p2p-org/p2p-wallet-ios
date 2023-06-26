//
//  HomeAccountListView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.06.2023.
//

import KeyAppUI
import SwiftUI

struct HomeAccountListView: View {
    @ObservedObject var viewModel: HomeAccountListViewModel

    @State var isHiddenSectionDisabled: Bool = true
    @State var currentUserInteractionCellID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            wrappedList(itemsCount: viewModel.accounts.count) {
                ForEach(viewModel.accounts, id: \.id) {
                    tokenCell(rendableAccount: $0, isVisiable: true)
                }
            }
            .cornerRadius(radius: 20, corners: .allCorners)
            .padding(.all, 16)

            if !viewModel.hiddenAccounts.isEmpty {
                Button(
                    action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation {
                            isHiddenSectionDisabled.toggle()
                        }
                    },
                    label: {
                        HStack(spacing: 8) {
                            Image(uiImage: isHiddenSectionDisabled ? .eyeHiddenTokens : .eyeHiddenTokensHide)
                            Text(L10n.hiddenTokens)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .font(.system(size: 16))
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                    }
                )
                if !isHiddenSectionDisabled {
                    wrappedList(itemsCount: viewModel.hiddenAccounts.count) {
                        ForEach(viewModel.hiddenAccounts, id: \.id) {
                            tokenCell(rendableAccount: $0, isVisiable: false)
                        }
                        .transition(AnyTransition.opacity.animation(.linear(duration: 0.3)))
                    }
                    .cornerRadius(radius: 20, corners: .allCorners)
                    .padding(.all, 16)
                }
            }
        }
    }

    private func tokenCell(rendableAccount: any RenderableAccount, isVisiable: Bool) -> some View {
        HomeAccountView(rendable: rendableAccount) {
            Task {
                viewModel.invoke(for: rendableAccount, event: .tap)
            }
        } onButtonTap: {
            Task {
                viewModel.invoke(for: rendableAccount, event: .extraButtonTap)
            }
        }
        .do { view in
            switch rendableAccount.extraAction {
            case .visiable:
                return AnyView(
                    view.swipeActions(
                        isVisible: isVisiable,
                        currentUserInteractionCellID: $currentUserInteractionCellID
                    ) {
                        Task {
                            await viewModel.invoke(for: rendableAccount, event: .visibleToggle)
                        }
                    }
                )
            case .none:
                return AnyView(view)
            }
        }
        .frame(height: 72)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func wrappedList<Content: View>(
        itemsCount: Int,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        List {
            content()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .frame(height: CGFloat(itemsCount) * 72)
    }
}

private extension View {
    @ViewBuilder func swipeActions(
        isVisible: Bool,
        currentUserInteractionCellID _: Binding<String?>,
        action: @escaping () -> Void
    ) -> some View {
        swipeActions(allowsFullSwipe: true) {
            Button(action: action) {
                Image(uiImage: isVisible ? .eyeHide : .eyeShow)
            }
            .tint(.clear)
        }
    }

    func hideView(isVisible: Bool) -> AnyView {
        Image(uiImage: isVisible ? .eyeHide : .eyeShow)
            .animation(.default)
            .castToAnyView()
    }
}

struct HomeAccountListView_Previews: PreviewProvider {
    static var previews: some View {
        HomeAccountListView(viewModel: .init())
    }
}
