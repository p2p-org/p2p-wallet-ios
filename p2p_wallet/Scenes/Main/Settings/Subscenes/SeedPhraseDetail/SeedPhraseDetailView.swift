// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

struct SeedPhraseDetailView: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    @ObservedObject var viewModel: SeedPhraseDetailViewModel

    var body: some View {
        GeometryReader { _ in
            VStack {
                VStack {
                    Image(uiImage: viewModel.state == .lock ? UIImage.fogOpen : UIImage.fogClose)
                    Text(viewModel.state == .lock ? L10n.showingSeedPhrase : L10n.yourSeedPhrase)
                        .fontWeight(.bold)
                        .apply(style: .title1)
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, safeAreaInsets.top + 60)
                .background(Color(Asset.Colors.lime.color))
                .cornerRadius(28)
                .overlay(centerText, alignment: .bottom)

                if viewModel.state == .lock {
                    VStack {
                        hintRow(text: L10n.aSeedPhraseIsLikeAPasswordWordsThatAllowsYouToAccessAndManageYourCryptoFunds)

                        hintRow(text: L10n.ExceptYouNoOneKeepsYourEntireSeedPhrase
                            .thePartsAreDistributedDecentralizedOnTorusNetworkNodes)
                            .padding(.top, 12)
                        hintRow(text: L10n.YourSeedPhraseMustNeverBeShared.keepItPrivateEvenFromUs)
                            .padding(.top, 12)
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
                            image: Asset.Icons.key.image,
                            style: .white
                        ) { value in if value { viewModel.unlock() } }
                            .frame(height: 56)
                    } else {
                        TextButtonView(
                            title: L10n.copy,
                            style: .third,
                            size: .large,
                            trailing: Asset.Icons.copy.image
                        ) { viewModel.copy() }
                            .frame(height: TextButton.Size.large.height)
                    }
                }
            }
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.top)
        .frame(maxHeight: .infinity)
        .navigationTitle(L10n.seedPhraseDetails)
        .navigationBarTitleDisplayMode(.inline)
    }

    var centerText: some View {
        Text(viewModel.state == .lock ? L10n.makeSureYouUnderstandTheseAspects : L10n.yourSeedPhraseMustNeverBeShared)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(32)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
            )
            .offset(x: 0, y: 16)
    }

    func hintRow(text: String) -> some View {
        HStack(alignment: .top) {
            Text("•")
            Text(LocalizedStringKey(text))
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
