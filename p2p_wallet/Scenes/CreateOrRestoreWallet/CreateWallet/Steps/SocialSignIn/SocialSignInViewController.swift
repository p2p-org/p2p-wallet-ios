// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AuthenticationServices
import BEPureLayout
import Foundation
import KeyAppUI

class SocialSignInViewController: BaseViewController {
    private let viewModel: SocialSignInViewModel
    override var preferredNavigationBarStype: NavigationBarStyle { .normal(translucent: false) }

    init(viewModel: SocialSignInViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func setUp() {
        super.setUp()

        navigationItem.title = L10n.createANewWallet

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
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        infoButton.tintColor = Asset.Colors.night.color
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    override func build() -> UIView {
        BEContainer {
            // Logo and description
            BEVStack {
                BESafeArea {
                    UIImageView(image: .introWelcomeToP2pFamily, contentMode: .scaleAspectFill)
                        .frame(width: 220, height: 280)
                        .centered(.horizontal)
                }

                BEVStack {
                    UILabel(
                        text: L10n.protectingTheFunds,
                        font: UIFont.font(of: .largeTitle, weight: .bold),
                        textAlignment: .center
                    )
                        .padding(.init(only: .top, inset: 10))
                    UILabel(
                        text: L10n.WeUseMultiFactorAuthentication
                            .youCanEasilyRegainAccessToTheWalletUsingSocialAccounts,
                        font: UIFont.font(of: .title3, weight: .regular),
                        numberOfLines: 3,
                        textAlignment: .center
                    ).padding(.init(only: .top, inset: 16))
                }.padding(.init(x: 16, y: 0))

                UIView.spacer

                BottomPanel {
                    BESafeArea {
                        BEVStack(alignment: .fill) {
                            // Buttons
                            TextButton(title: "Sign in with Apple", style: .inverted, size: .large, leading: .appleLogo)
                                .onPressed { [weak viewModel] _ in viewModel?.input.onSignInWithApple.send() }
                            UIView().frame(height: 16)
                            TextButton(title: "Sign in with Google", style: .inverted, size: .large, leading: .google)
                                .onPressed { [weak viewModel] _ in viewModel?.input.onSignInWithGoogle.send() }

                            UIView().frame(height: 24)

                            // Term and conditions
                            UILabel(
                                text: L10n.byContinuingYouAgreeToKeyAppS,
                                textColor: .white.withAlphaComponent(0.65),
                                textAlignment: .center
                            )
                            BECenter {
                                TextButton(title: L10n.termsAndConditions, style: .ghostWhite, size: .small)
                                    .onPressed { [weak viewModel] _ in
                                        viewModel?.input.onTermAndCondition.send()
                                    }
                            }.frame(height: 30)
                        }.padding(.init(top: 32, left: 24, bottom: 0, right: 24))
                    }
                }
            }
        }.backgroundColor(color: Asset.Colors.lime.color)
    }

    @objc func onBack() {
        viewModel.input.onBack.send()
    }

    @objc func signInWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension SocialSignInViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        view.window!
    }
}

extension SocialSignInViewController: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            guard let idToken = appleIDCredential.identityToken else { return }
            let idTokenStr = String(data: idToken, encoding: .utf8)!

            Task {
                do {
                    let state = try await viewModel
                        .createWalletViewModel
                        .onboardingStateMachine
                        .accept(event: .signIn(tokenID: idTokenStr, authProvider: .apple))
                    print(state as Any)
                } catch {
                    print(error)
                }
            }
        case _ as ASPasswordCredential:
            break
        default:
            break
        }
    }
}
