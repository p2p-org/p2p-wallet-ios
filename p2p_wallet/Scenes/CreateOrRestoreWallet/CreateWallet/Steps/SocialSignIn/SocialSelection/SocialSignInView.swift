// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

struct SocialSignInView: View {
    @ObservedObject var viewModel: SocialSignInViewModel

    var body: some View {
        VStack {
            Spacer()
            content
            Spacer()
            actions
        }
        .onboardingNavigationBar(
            title: L10n.createAccount,
            onBack: { [weak viewModel] in viewModel?.onBack() },
            onInfo: { [weak viewModel] in viewModel?.onInfo() }
        )
        .onboardingScreen()
    }

    var content: some View {
        OnboardingContentView(
            data: .init(
                image: .introWelcomeToP2pFamily,
                title: L10n.protectingTheFunds,
                subtitle: L10n.WeUseMultiFactorAuthentication
                    .youCanEasilyRegainAccessToTheWalletUsingSocialAccounts
            )
        ).padding(.horizontal, 40)
    }

    var actions: some View {
        BottomActionContainer {
            VStack(spacing: .zero) {
                TextButtonView(
                    title: "Sign in with Apple",
                    style: .inverted,
                    size: .large,
                    leading: .appleLogo,
                    isLoading: viewModel.loading == .appleButton,
                    onPressed: { [weak viewModel] in viewModel?.onSignInTap(.apple) }
                )
                    .frame(height: TextButton.Size.large.height)
                    .disabled(viewModel.loading == .googleButton)
                TextButtonView(
                    title: "Sign in with Google",
                    style: .inverted,
                    size: .large,
                    leading: .google,
                    isLoading: viewModel.loading == .googleButton,
                    onPressed: { [weak viewModel] in viewModel?.onSignInTap(.google) }
                )
                    .frame(height: TextButton.Size.large.height)
                    .padding(.top, 12)
                    .disabled(viewModel.loading == .appleButton)
            }
        }
    }
}
