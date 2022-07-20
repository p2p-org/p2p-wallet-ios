// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AuthenticationServices
import BEPureLayout
import Foundation

extension SocialSignIn {
    class ViewController: BaseViewController {
        private weak var coordinator: NewCreateWallet.Coordinator?

        init(coordinator: NewCreateWallet.Coordinator) {
            self.coordinator = coordinator
            super.init()
        }

        override func build() -> UIView {
            BECenter {
                UILabel(text: "Sign in screen")
                // UIButton(type: .system)
                //     .setup { button in
                //         button.setTitle("Sign in with apple", for: .normal)
                //         button.setTitleColor(.blue, for: .normal)
                //         button.addTarget(self, action: #selector(signInWithGoogle), for: .touchUpInside)
                //     }
                ASAuthorizationAppleIDButton()
                    .setup { button in
                        button.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)
                    }
                UILabel(text: ":)")
            }
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

        @objc func signInWithGoogle() {
            Task {
                do {
                    try await coordinator?.submitEvent(event: .signIn(tokenID: "Token", authProvider: .google))
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension SocialSignIn.ViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        view.window!
    }
}

extension SocialSignIn.ViewController: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            guard let idToken = appleIDCredential.identityToken else { return }
            let idTokenStr = String(data: idToken, encoding: .utf8)!
            
            // TODO: remove
            print(idTokenStr)
            
            Task {
                do {
                    let state = try await coordinator?
                        .submitEvent(event: .signIn(tokenID: idTokenStr, authProvider: .apple))
                    print(state as Any)
                } catch {
                    print(error)
                }
            }
        case let passwordCredential as ASPasswordCredential:
            break
        default:
            break
        }
    }
}
