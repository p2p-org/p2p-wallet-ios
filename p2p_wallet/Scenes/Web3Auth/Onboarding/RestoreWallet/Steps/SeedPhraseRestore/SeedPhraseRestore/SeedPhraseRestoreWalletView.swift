import Combine
import SwiftUI

struct SeedPhraseRestoreWalletView: View {
    @ObservedObject var viewModel: SeedPhraseRestoreWalletViewModel

    init(viewModel: SeedPhraseRestoreWalletViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            VStack {
                Text(L10n.enterYourSolanaWalletSeedPhrase)
                    .apply(style: .text3)
                    .foregroundColor(Color(.mountain))
                    .padding(.top, 4)
                inputView.padding(.top, 2)

                if !viewModel.suggestions.isEmpty { suggestions }

                Spacer()
            }

            TextButtonView(
                title: viewModel.canContinue ? L10n.continue : L10n.fill12Or24Words,
                style: .primary,
                size: .large,
                trailing: viewModel.canContinue ? UIImage(resource: .arrowForward) : nil
            ) { [weak viewModel] in viewModel?.continueButtonTapped() }
                .frame(height: 56)
                .disabled(!viewModel.canContinue)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
        }
        .onboardingNavigationBar(title: L10n.restoreYourWallet) { [weak viewModel] in
            viewModel?.back.send()
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { viewModel.isSeedFocused = true } }
        .onDisappear { viewModel.isSeedFocused = false }
    }

    var inputView: some View {
        VStack {
            VStack {
                HStack {
                    Text(viewModel.canContinue ? "\(L10n.seedPhrase) ✅" : L10n.seedPhrase)
                        .apply(style: .text4)
                        .foregroundColor(Color(.mountain))
                        .padding(.top, 17)
                    Spacer()
                    HStack {
                        pasteButton
                        if !viewModel.seed.isEmpty {
                            clearButton
                                .animation(.default)
                                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
                                .padding(.leading, 5)
                        }
                    }
                    .frame(height: 32, alignment: .trailing)
                    .padding(.top, 11)
                }

                SeedPhraseTextView(text: $viewModel.seed, isFirstResponder: $viewModel.isSeedFocused)
                    .frame(maxHeight: 343)
                    .colorMultiply(Color(.smoke))

            }.padding(.horizontal, 12)
        }
        .background(Color(.smoke))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.rain), lineWidth: 1)
        )
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    var pasteButton: some View {
        HStack {
            Image(.copy)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(.black)
            Text(L10n.paste)
                .font(uiFont: UIFont.font(of: .text4))
                .foregroundColor(.black)
        }
        .frame(height: 32)
        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 14))
        .background(viewModel.seed.isEmpty ? Color(.lime) : Color.clear)
        .cornerRadius(8)
        .fixedSize()
        .onTapGesture {
            viewModel.paste()
        }
    }

    var clearButton: some View {
        HStack {
            Text(L10n.clear)
                .font(uiFont: UIFont.font(of: .text4))
                .foregroundColor(.black)
            Image(.clear)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(.black)
        }
        .frame(height: 32)
        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 14))
        .background(Color(.rain))
        .cornerRadius(8)
        .fixedSize()
        .onTapGesture {
            viewModel.clear()
        }
    }

    var suggestions: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.suggestions, id: \.self) { word in
                self.suggestionView(with: word)
            }
        }.padding([.leading, .trailing], 16)
    }

    func suggestionView(with word: String) -> some View {
        Text(word).apply(style: .text3)
            .fixedSize(horizontal: true, vertical: true)
            .frame(maxWidth: UIScreen.main.bounds.width, minHeight: 38)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.rain), lineWidth: 1)
            )
    }
}
