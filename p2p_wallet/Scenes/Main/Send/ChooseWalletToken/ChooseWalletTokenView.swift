import SwiftUI
import KeyAppUI
import SolanaSwift

struct ChooseWalletTokenView: View {
    @ObservedObject private var viewModel: ChooseWalletTokenViewModel

    init(viewModel: ChooseWalletTokenViewModel) {
        self.viewModel = viewModel
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
                if viewModel.wallets.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }

    @ViewBuilder
    private func wrappedList<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if #available(iOS 15, *) {
            List {
                content()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
            .background(Color(Asset.Colors.smoke.color))
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    content()
                }
                .background(Color(Asset.Colors.smoke.color))
            }
        }
    }

    private func state(for wallet: Wallet) -> ChooseWalletTokenItemView.State {
        if viewModel.wallets.count == 1 {
            return .single
        } else if viewModel.wallets.first == wallet {
            return .first
        } else if viewModel.wallets.last == wallet {
            return .last
        } else {
            return .other
        }
    }
}

// MARK: - Subviews
private extension ChooseWalletTokenView {
    private var emptyView: some View {
        Group {
            SendNotFoundView(text: L10n.TokenNotFound.tryAnotherOne)
                .padding(.top, 30)
            Spacer()
        }
    }

    private var listView: some View {
        wrappedList {
            if !viewModel.isSearchGoing {
                // Chosen token
                Text(L10n.chosenToken)
                    .sectionStyle()
                ChooseWalletTokenItemView(wallet: viewModel.chosenToken, state: .single)
                    .listRowBackground(Color(Asset.Colors.smoke.color))
                    .onTapGesture {
                        viewModel.chooseTokenSubject.send(viewModel.chosenToken)
                    }
            }

            // Search resuls or all tokens
            Text(viewModel.isSearchGoing ? L10n.hereSWhatWeFound : L10n.otherTokens)
                .sectionStyle()

            ForEach(viewModel.wallets) { wallet in
                ChooseWalletTokenItemView(wallet: wallet, state: state(for: wallet))
                    .listRowBackground(Color(Asset.Colors.smoke.color))
                    .onTapGesture {
                        viewModel.chooseTokenSubject.send(wallet)
                    }
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
