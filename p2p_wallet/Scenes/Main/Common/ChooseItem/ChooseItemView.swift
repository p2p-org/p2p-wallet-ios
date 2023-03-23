import SwiftUI
import KeyAppUI
import SolanaSwift

struct ChooseItemView<Content: View>: View {
    @ObservedObject private var viewModel: ChooseItemViewModel
    @ViewBuilder private let content: (ChooseItemSearchableItemViewModel) -> Content

    init(
        viewModel: ChooseItemViewModel,
        @ViewBuilder content: @escaping (ChooseItemSearchableItemViewModel) -> Content
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
                    isSearchFieldFocused: $viewModel.isSearchFieldFocused
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // List of tokens
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.sections.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .ignoresSafeArea(.keyboard)
        }
    }

    private func state(for item: any ChooseItemSearchableItem, in section: ChooseItemListSection) -> ChooseItemSearchableItemViewState {
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
        ChooseItemSearchableItemLoadingView()
    }

    private var listView: some View {
        WrappedList {
            if !viewModel.isSearchGoing {
                // Chosen token
                Text(L10n.chosenToken.uppercased())
                    .sectionStyle()
                ChooseItemSearchableItemView(
                    content: content,
                    state: .single,
                    item: viewModel.chosenToken,
                    isChosen: true
                )
                .onTapGesture {
                    viewModel.chooseTokenSubject.send(viewModel.chosenToken)
                }
            }

            // Search resuls or all tokens
            Text(viewModel.isSearchGoing ? L10n.hereSWhatWeFound.uppercased() : viewModel.otherTokensTitle.uppercased())
                .sectionStyle()

            ForEach(viewModel.sections) { section in
                ForEach(section.items.map({Container(wrapped: $0)})) { singleWallet  in
                    ChooseItemSearchableItemView(
                        content: content,
                        state: state(for: singleWallet.wrapped, in: section),
                        item: singleWallet.wrapped,
                        isChosen: false
                    )
                    .onTapGesture {
                        viewModel.chooseTokenSubject.send(singleWallet.wrapped)
                    }
                }
                spacer(height: 12)
            }
            spacer(height: 28)
        }
        .modifier(ListBackgroundModifier(separatorColor: Asset.Colors.smoke.color))
        .environment(\.defaultMinListRowHeight, 12)
        .scrollDismissesKeyboard()
    }

    func spacer(height: CGFloat) -> some View {
        Spacer()
            .listRowBackground(Color(Asset.Colors.smoke.color))
            .frame(height: height)
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
    var wrapped: any ChooseItemSearchableItem
    var id: String { wrapped.id }
}
