// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AuthenticationServices
import Foundation
import KeyAppUI

class RestoreFlowsViewController: BaseViewController {
    enum Flow {
        case withDeviceShare
        case withCustomShare
    }

    let viewModel: RestoreWalletViewModel

    var flow: Flow = .withDeviceShare
    var deviceShare: String {
        UserDefaults.standard.string(forKey: "deviceShare") ?? "No data"
    }

    init(viewModel: RestoreWalletViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func build() -> UIView {
        BEContainer {
            BECenter {
                UILabel(text: "Device share: \(deviceShare)", numberOfLines: 4)
                TextButton(title: "Sign in with device share", style: .primary, size: .medium)
                    .onTap { [weak self] in
                        self?.flow = .withDeviceShare
                        self?.signInWithApple()
                    }
                UIView().frame(height: 8)
                TextButton(title: "Sign in with custom share", style: .primary, size: .medium)
                    .onTap { [weak self] in
                        self?.flow = .withCustomShare
                        self?.signInWithApple()
                    }
            }
        }.backgroundColor(color: Asset.Colors.lime.color)
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

extension RestoreFlowsViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        view.window!
    }
}

extension RestoreFlowsViewController: ASAuthorizationControllerDelegate {
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
                    switch flow {
                    case .withDeviceShare:
                        let state = try await viewModel
                            .stateMachine
                            .accept(event: .signInWithDeviceShare(tokenID: idTokenStr, deviceShare: deviceShare))
                    case .withCustomShare:
                        let state = try await viewModel
                            .stateMachine
                            .accept(event: .signInWithCustomShare(tokenID: idTokenStr))
                    }
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
