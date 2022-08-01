// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AuthenticationServices
import BEPureLayout
import Combine
import Foundation
import KeyAppUI

class SocialSignInTryAgainViewController: BaseViewController {
    let viewModel: SocialSignInTryAgainViewModel

    init(viewModel: SocialSignInTryAgainViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func build() -> UIView {
        BEContainer {
            // Logo and description
            BEVStack {
                BESafeArea {
                    BEVStack {
                        UIImageView(image: .introWelcomeToP2pFamily, contentMode: .scaleAspectFill)
                            .frame(width: 220, height: 280)
                            .centered(.horizontal)

                        UILabel(
                            text: "Wooow 🦄",
                            font: UIFont.font(of: .largeTitle, weight: .bold),
                            textAlignment: .center
                        )
                            .padding(.init(only: .top, inset: 10))
                        UILabel(
                            text: L10n.YouVeFindASeldonPage.ItSLikeAUnicornButCrush.weReAlreadyFixingIt,
                            font: UIFont.font(of: .title3, weight: .regular),
                            numberOfLines: 3,
                            textAlignment: .center
                        ).padding(.init(only: .top, inset: 16))
                    }.padding(.init(x: 16, y: 0))
                }.centered(.vertical)

                BottomPanel {
                    BESafeArea {
                        BEVStack(alignment: .fill) {
                            // Buttons
                            TextButton(title: L10n.tryAgain, style: .inverted, size: .large)
                                .onPressed { [weak viewModel] _ in viewModel?.input.onTryAgain.send() }
                            UIView().frame(height: 16)
                            TextButton(title: L10n.startingScreen, style: .ghostLime, size: .large)
                                .onPressed { [weak viewModel] _ in viewModel?.input.onStartScreen.send() }
                        }.padding(.init(top: 32, left: 24, bottom: 0, right: 24))
                    }
                }
            }
        }.backgroundColor(color: Asset.Colors.lime.color)
    }
}
