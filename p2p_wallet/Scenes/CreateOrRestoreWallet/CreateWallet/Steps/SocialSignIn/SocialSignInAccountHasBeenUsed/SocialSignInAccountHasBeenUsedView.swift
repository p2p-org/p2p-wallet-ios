// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Combine
import Foundation
import KeyAppUI
import SwiftUI

struct SocialSignInAccountHasBeenUsedView: View {
    @ObservedObject var viewModel: SocialSignInAccountHasBeenUsedViewModel

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(
                data: .init(
                    image: .walletFound,
                    title: L10n.aWalletFound,
                    subtitles: [
                        OnboardingContentData.Subtitle(text: L10n.looksLikeYouAlreadyHaveAWalletWith),
                        OnboardingContentData.Subtitle(text: viewModel.emailAddress, isLimited: true),
                    ]
                )
            )
            Spacer()

            BottomActionContainer {
                VStack {
                    NewTextButton(
                        title: L10n.useAnotherAccount,
                        style: .inverted,
                        isLoading: viewModel.loading,
                        leading: .google
                    ) { [weak viewModel] in viewModel?.userAnotherAccount() }
                        .disabled(viewModel.loading)

                    // Restore button
                    NewTextButton(
                        title: L10n.continueRestoringThisWallet,
                        style: .ghostLime
                    ) { [weak viewModel] in viewModel?.switchToRestore() }
                        .disabled(viewModel.loading)
                        .padding(.top, 12)
                }
            }
        }
        .onboardingNavigationBar(
            title: L10n.stepOf("1", "3"),
            onBack: { [weak viewModel] in viewModel?.back() },
            onInfo: { [weak viewModel] in viewModel?.info() }
        )
        .onboardingScreen()
    }
}
