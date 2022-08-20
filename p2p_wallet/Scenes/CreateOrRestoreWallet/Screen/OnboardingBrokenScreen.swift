// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import KeyAppUI
import SwiftUI

struct OnboardingBrokenScreen: View {
    struct Coordinator {
        let backHome: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let help: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let info: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
    }

    let title: String
    let coordinator: Coordinator = .init()

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(
                data: .init(
                    image: .introWelcomeToP2pFamily,
                    title: L10n.protectingTheFunds,
                    subtitle: L10n.WeUseMultiFactorAuthentication
                        .youCanEasilyRegainAccessToTheWalletUsingSocialAccounts
                )
            )
                .padding(.horizontal, 40)
                .padding(.top, 60)
                .padding(.bottom, 48)
            BottomActionContainer {
                VStack {
                    TextButtonView(
                        title: L10n.writeToHeeeeelp,
                        style: .inverted,
                        size: .large,
                        leading: Asset.MaterialIcon.newReleasesOutlined.image
                    ) { [coordinator] in coordinator.help.sendProcess { _ in } }
                        .frame(height: TextButton.Size.large.height)
                    TextButtonView(
                        title: L10n.startingScreen,
                        style: .ghostLime,
                        size: .large
                    ) { [coordinator] in coordinator.backHome.sendProcess { _ in } }
                        .frame(height: TextButton.Size.large.height)
                }
            }
        }
        .onboardingNavigationBar(
            title: title,
            onBack: nil,
            onInfo: { [coordinator] in coordinator.info.sendProcess { _ in } }
        )
        .onboardingScreen()
    }
}

struct OnboardingBrokenScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OnboardingBrokenScreen(title: L10n.restore)
        }
    }
}
