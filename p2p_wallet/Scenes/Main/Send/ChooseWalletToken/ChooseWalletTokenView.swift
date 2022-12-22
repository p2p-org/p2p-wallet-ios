import SwiftUI
import KeyAppUI
import SolanaSwift

struct ChooseWalletTokenView: View {
    @ObservedObject private var viewModel: ChooseWalletTokenViewModel

    init(viewModel: ChooseWalletTokenViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                manualNavBar

                searchField
                    .padding(.horizontal, 16)

                if viewModel.isLoading {
                    loadingView
                        .padding(.top, 64)
                } else {
                    if viewModel.wallets.isEmpty {
                        emptyView
                            .padding(.top, 30)
                            .edgesIgnoringSafeArea(.bottom)
                    } else {
                        wrappedList {
                            if !viewModel.isSearchGoing {
                                chosenTokenSection
                                    .onTapGesture {
                                        viewModel.chooseTokenSubject.send(viewModel.chosenToken)
                                    }
                            }
                            
                            Text(viewModel.isSearchGoing ? L10n.hereSWhatWeFound : L10n.otherTokens)
                                .sectionStyle()
                            
                            ForEach(viewModel.wallets) { wallet in
                                ChooseWalletTokenItemView(
                                    token: wallet.token,
                                    amount: wallet.amount,
                                    amountInCurrentFiat: wallet.amountInCurrentFiat,
                                    state: state(for: wallet)
                                )
                                .listRowBackground(Color(Asset.Colors.smoke.color))
                                .onTapGesture {
                                    viewModel.chooseTokenSubject.send(wallet)
                                }
                            }
                        }
                        .padding(.bottom, 28)
                        .edgesIgnoringSafeArea(.bottom)
                        .endEditingKeyboardOnDragGesture()
                    }
                }
            }
        }.onDisappear {
            DispatchQueue.main.async {
                self.viewModel.isSearchFieldFocused = false
            }
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
    private var manualNavBar: some View {
        ZStack(alignment: .center) {
            Text(viewModel.title)
                .font(uiFont: .font(of: .text1, weight: .semibold))
                .foregroundColor(Color(Asset.Colors.night.color))
            HStack {
                Spacer()
                Button(
                    action: viewModel.close.send,
                    label: {
                        Image(uiImage: Asset.MaterialIcon.close.image)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 18)
                    }
                )
            }
        }
        .frame(height: 48)
    }

    private var emptyView: some View {
        VStack {
            SendNotFoundView(text: L10n.TokenNotFound.tryAnotherOne)
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack {
            ChooseWalletTokenSkeletonView()
                .frame(height: 88)
                .padding(.horizontal, 16)
            Spacer()
        }
    }

    private var searchField: some View {
        HStack(spacing: .zero) {
            Image(uiImage: .standardSearch)
                .searchFieldStyle()

            FocusedTextField(
                text: $viewModel.searchText,
                isFirstResponder: $viewModel.isSearchFieldFocused
            ) { textField in
                textField.returnKeyType = .done
                textField.backgroundColor = Asset.Colors.rain.color
                textField.placeholder = L10n.search
                textField.font = .font(of: .text3)
            }

            if !viewModel.searchText.isEmpty {
                Button(action: viewModel.clearSearch.send) {
                    Image(uiImage: .clean)
                        .searchFieldStyle()
                }
                .frame(height: 44)
            }
        }
        .background(Color(Asset.Colors.rain.color))
        .cornerRadius(12)
        .frame(height: 44)
    }

    private var chosenTokenSection: some View {
        Group {
            Text(L10n.chosenToken)
                .sectionStyle()
            ChooseWalletTokenItemView(
                token: viewModel.chosenToken.token,
                amount: viewModel.chosenToken.amount,
                amountInCurrentFiat: viewModel.chosenToken.amountInCurrentFiat,
                state: .single
            )
            .listRowBackground(Color(Asset.Colors.smoke.color))
        }
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

private extension Image {
    func searchFieldStyle() -> some View {
        return self
            .renderingMode(.template)
            .foregroundColor(Color(Asset.Colors.mountain.color))
            .frame(width: 20, height: 20)
            .padding(.horizontal, 10)
    }
}
