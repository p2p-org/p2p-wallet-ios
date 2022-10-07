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
            title: viewModel.title,
            onBack: viewModel.isBackAvailable ? { [weak viewModel] in viewModel?.onBack() } : nil,
            onInfo: { [weak viewModel] in viewModel?.onInfo() }
        )
        .onboardingScreen()
    }

    var content: some View {
        OnboardingContentView(data: viewModel.content)
    }

    var actions: some View {
        BottomActionContainer {
            VStack(spacing: .zero) {
                TextButtonView(
                    title: viewModel.appleButtonTitle,
                    style: .inverted,
                    size: .large,
                    leading: .appleLogo,
                    isLoading: viewModel.loading == .appleButton,
                    onPressed: { [weak viewModel] in
                        guard viewModel?.loading == nil else { return }
                        viewModel?.onSignInTap(.apple)
                    }
                )
                    .frame(height: TextButton.Size.large.height)
                TextButtonView(
                    title: viewModel.googleButtonTitle,
                    style: .inverted,
                    size: .large,
                    leading: .google,
                    isLoading: viewModel.loading == .googleButton,
                    onPressed: { [weak viewModel] in
                        guard viewModel?.loading == nil else { return }
                        viewModel?.onSignInTap(.google)
                    }
                )
                    .frame(height: TextButton.Size.large.height)
                    .padding(.top, 12)
            }
        }
    }
}
