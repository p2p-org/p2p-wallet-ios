// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Combine
import Foundation
import KeyAppUI

class SocialSignInAccountHasBeenUsedViewController: BaseViewController {
    let viewModel: SocialSignInAccountHasBeenUsedViewModel
    var subscriptions = [AnyCancellable]()

    init(viewModel: SocialSignInAccountHasBeenUsedViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func setUp() {
        super.setUp()

        viewModel.output
            .isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                isLoading ? self?.showIndetermineHud() : self?.hideHud()
            }.store(in: &subscriptions)

        navigationItem.title = L10n.stepOf("1", "3")

        // Left button
        let backButton = UIBarButtonItem(
            image: UINavigationBar.appearance().backIndicatorImage,
            style: .plain,
            target: self,
            action: #selector(onBack)
        )
        backButton.tintColor = Asset.Colors.night.color

        let spacing = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacing.width = 8

        navigationItem.setLeftBarButtonItems([spacing, backButton], animated: false)

        // Right button
        let infoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        // infoButton.addTarget(self, action: #selector(onInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        infoButton.tintColor = Asset.Colors.night.color
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    override func build() -> UIView {
        BEContainer {
            BEVStack {
                // Logo and description
                UIView.spacer

                BESafeArea {
                    UIImageView(image: .introWelcomeToP2pFamily, contentMode: .scaleAspectFill)
                        .frame(width: 220, height: 280)
                        .centered(.horizontal)
                }

                BEVStack {
                    UILabel(
                        text: L10n.aWalletFound,
                        font: UIFont.font(of: .largeTitle, weight: .bold),
                        textAlignment: .center
                    )
                        .padding(.init(only: .top, inset: 10))
                    UILabel(
                        text: L10n.looksLikeYouAlreadyHaveAWalletWith("?"),
                        font: UIFont.font(of: .title3, weight: .regular),
                        numberOfLines: 3,
                        textAlignment: .center
                    ).setup { label in
                        viewModel.output.emailAddress.sink { [weak label] email in
                            label?.text = L10n.looksLikeYouAlreadyHaveAWalletWith(email)
                        }.store(in: &subscriptions)
                    }
                    .padding(.init(only: .top, inset: 16))
                }.padding(.init(x: 16, y: 0))

                UIView(height: 48)

                // Bottom panel
                BottomPanel {
                    BESafeArea {
                        BEVStack(alignment: .fill) {
                            // Use another account button
                            TextButton(
                                title: L10n.useAnotherAccount,
                                style: .inverted,
                                size: .large,
                                leading: .google
                            )
                                .onPressed { [weak viewModel] _ in viewModel?.input.useAnotherAccount.send() }

                            UIView().frame(height: 16)

                            // Restore button
                            TextButton(
                                title: L10n.continueRestoringThisWallet,
                                style: .ghostLime,
                                size: .large
                            )
                                .onPressed { [weak viewModel] _ in viewModel?.input.restoreThisWallet.send() }
                        }.padding(.init(top: 32, left: 24, bottom: 0, right: 24))
                    }
                }
            }
        }.backgroundColor(color: Asset.Colors.lime.color)
    }

    @objc func onBack() {
        viewModel.input.onBack.send()
    }
}
