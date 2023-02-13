import SwiftUI
import KeyAppUI
import SolanaSwift

struct ChooseItemView<Content: View>: View {
    @ObservedObject private var viewModel: ChooseItemViewModel
    @ViewBuilder private let content: (any SearchableItem) -> Content

    init(
        viewModel: ChooseItemViewModel,
        @ViewBuilder content: @escaping (any SearchableItem) -> Content
    ) {
        self.viewModel = viewModel
        self.content = content
    }

    var body: some View {
        ColoredBackground {
            VStack(spacing: 16) {
                // Search field
                SearchField(
                    searchText: $viewModel.searchText,
                    isSearchFieldFocused: $viewModel.isSearchFieldFocused,
                    clearSearchAction: viewModel.clearSearch.send
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // List of tokens
                if viewModel.isLoading {
                    loadingView
                        .padding(.top, 64)
                } else if viewModel.wallets.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }

    private func state(for item: any SearchableItem, in section: ChooseItemListData) -> SearchableItemViewState {
        if section.items.count == 1 {
            return .single
        } else if section.items.first?.id == item.id {
            return .first
        } else if section.items.last?.id == item.id {
            return .last
        } else {
            return .other
        }
    }
}

// MARK: - Subviews
private extension ChooseItemView {
    private var emptyView: some View {
        Group {
            NotFoundView(text: L10n.TokenNotFound.tryAnotherOne)
                .padding(.top, 30)
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack {
            SearchableItemSkeletonView()
                .frame(height: 88)
                .padding(.horizontal, 16)
            Spacer()
        }
    }

    private var listView: some View {
        WrappedList {
            if !viewModel.isSearchGoing {
                // Chosen token
                Text(L10n.chosenToken)
                    .sectionStyle()
                SearchableItemView(content: content, state: .single, item: viewModel.chosenToken)
                    .listRowBackground(Color(Asset.Colors.smoke.color))
                    .onTapGesture {
                        viewModel.chooseTokenSubject.send(viewModel.chosenToken)
                    }
            }

            // Search resuls or all tokens
            Text(viewModel.isSearchGoing ? L10n.hereSWhatWeFound : L10n.otherTokens)
                .sectionStyle()

            ForEach(viewModel.wallets) { section in
                ForEach(section.items.map({Container(wrapped: $0)})) { singleWallet  in
                    SearchableItemView(content: content, state: state(for: singleWallet.wrapped, in: section), item: singleWallet.wrapped)
                        .listRowBackground(Color(Asset.Colors.smoke.color))
                        .onTapGesture {
                            viewModel.chooseTokenSubject.send(singleWallet.wrapped)
                        }
                }
                Rectangle()
                    .frame(height: 12)
                    .foregroundColor(Color(Asset.Colors.smoke.color))
            }
        }
        .padding(.bottom, 28)
        .endEditingKeyboardOnDragGesture()
    }
}

private extension Text {
    func sectionStyle() -> some View {
        return self.apply(style: .text4)
            .foregroundColor(Color(Asset.Colors.mountain.color))
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 12, trailing: 20))
            .listRowBackground(Color(Asset.Colors.smoke.color))
    }
}

private struct Container: Identifiable {
    var wrapped: any SearchableItem
    var id: String { wrapped.id }
}
