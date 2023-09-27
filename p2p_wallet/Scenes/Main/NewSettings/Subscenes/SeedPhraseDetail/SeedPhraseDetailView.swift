import SwiftUI

struct SeedPhraseDetailView: View {
    @ObservedObject var viewModel: SeedPhraseDetailViewModel

    var body: some View {
        ExplainLayoutView {
            VStack {
                Image(viewModel.state == .lock ? .fogOpen : .fogClose)
                Text(viewModel.state == .lock ? L10n.showSeedPhrase : L10n.yourSeedPhrase)
                    .fontWeight(.bold)
                    .apply(style: .title1)
                    .padding(.bottom, 48)
            }
        } content: {
            VStack {
                if viewModel.state == .lock {
                    VStack(spacing: 12) {
                        ExplainText(text: L10n
                            .ASeedPhraseIsLikeAPassword.itAllowsYouToAccessAndManageYourCrypto)
                        ExplainText(text: L10n.ApartFromYouNoOneKeepsYourEntireSeedPhrase
                            .thePartsAreDistributedDecentralizedOnTorusNetworkNodes)
                        attributedText
                        Spacer()
                    }
                    .padding(.top, 36)
                    .padding(.horizontal, 16)
                } else {
                    SeedPhraseView(seedPhrase: viewModel.phrase)
                        .padding(.top, 24)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 26)
                }

                BottomActionContainer {
                    if viewModel.state == .lock {
                        SliderButtonView(
                            title: L10n.showMySeedPhrase,
                            image: .init(resource: .key),
                            style: .white,
                            isOn: $viewModel.isSliderOn
                        )
                        .frame(height: 56)
                    } else {
                        TextButtonView(
                            title: L10n.copy,
                            style: .third,
                            size: .large,
                            trailing: .init(resource: .copyFilled)
                        ) { viewModel.copy() }
                            .frame(height: TextButton.Size.large.height)
                    }
                }
            }
        } hint: {
            centerText
        }
    }

    var centerText: some View {
        Text(viewModel.state == .lock ? L10n.makeSureYouUnderstandTheseAspects : L10n.yourSeedPhraseMustNeverBeShared)
            .font(uiFont: .font(of: viewModel.state == .lock ? .text1 : .text4, weight: .semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(32)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color(.rain), lineWidth: 1)
            )
            .offset(x: 0, y: 16)
    }

    private var attributedText: some View {
        HStack(alignment: .top) {
            Text("•")
            Text(viewModel.thirdRowText)
            Spacer()
        }
    }
}

struct SeedPhraseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SeedPhraseDetailView(viewModel: SeedPhraseDetailViewModel(initialState: .unlock))
        }
    }
}
