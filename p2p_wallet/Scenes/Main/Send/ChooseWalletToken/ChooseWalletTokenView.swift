import SwiftUI
import KeyAppUI
import SolanaSwift

struct ChooseWalletTokenView: View {
    @ObservedObject private var viewModel: ChooseWalletTokenViewModel
    @Binding var showModal: Bool // TODO: Should be removed when coordinator is done

    init(viewModel: ChooseWalletTokenViewModel, showModal: Binding<Bool>) {
        self.viewModel = viewModel
        _showModal = showModal
    }

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                manualNavBar

                searchField
                    .padding(.horizontal, 16)

                if viewModel.wallets.isEmpty {
                    emptyView
                        .padding(.top, 48)
                } else {
                    wrappedList {
                        if !viewModel.isSearchGoing {
                            chosenTokenSection
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
        } else {
            LazyVStack(spacing: 0) {
                content()
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
            Text(L10n.pickAToken)
                .font(uiFont: .font(of: .text1, weight: .semibold))
                .foregroundColor(Color(Asset.Colors.night.color))
            HStack {
                Spacer()
                Button(action: {
                    viewModel.close.send()
                    showModal.toggle()
                }) {
                    Image(uiImage: Asset.MaterialIcon.close.image)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .frame(width: 24, height: 24)
                        .padding(.trailing, 18)
                }
            }
        }
        .frame(height: 48)
    }

    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(uiImage: .womanNotFound)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 220)
            Text(L10n.TokenNotFound.tryAnotherOne)
            Spacer()
        }
    }

    private var searchField: some View {
        FocusedTextField(
            text: $viewModel.searchText,
            isFirstResponder: $viewModel.isSearchFieldFocused
        ) { textField in

            let iconView = UIImageView(frame: CGRect(x: 10, y: 5, width: 20, height: 20))
            iconView.image = .standardSearch.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = Asset.Colors.mountain.color
            let iconContainerView: UIView = UIView(frame: CGRect(x: 20, y: 0, width: 36, height: 30))
            iconContainerView.addSubview(iconView)
            textField.leftView = iconContainerView
            textField.leftViewMode = .always

            let closeView = UIButton(frame: CGRect(x: 4, y: 5, width: 20, height: 20))
            closeView.setImage(.clean.withRenderingMode(.alwaysTemplate), for: .normal)
            closeView.tintColor = Asset.Colors.mountain.color
            closeView.onTap { [weak viewModel] in viewModel?.clearSearch.send() }
            let closeContainerView: UIView = UIView(frame: CGRect(x: 10, y: 0, width: 36, height: 30))
            closeContainerView.addSubview(closeView)
            textField.rightView = closeContainerView
            textField.rightViewMode = .whileEditing

            textField.returnKeyType = .done
            textField.backgroundColor = Asset.Colors.rain.color
            textField.placeholder = L10n.search
            textField.font = .font(of: .text3)
        }
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
