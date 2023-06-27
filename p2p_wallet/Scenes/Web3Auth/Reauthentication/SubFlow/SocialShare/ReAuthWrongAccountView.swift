//
//  ReAuthSocialSignInView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import KeyAppUI
import Onboarding
import SwiftUI

struct ReAuthWrongAccountView: View {
    let provider: SocialProvider
    let expectedEmail: String

    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(data: .init(
                image: .womanNotFound,
                title: L10n.incorrectID(provider.asString),
                subtitle: L10n.ThisAccountIsAssociatedWith.pleaseLogInWithTheCorrectID(expectedEmail, provider.asString)
            ))
            Spacer()
            BottomActionContainer {
                VStack(spacing: .zero) {
                    NewTextButton(
                        title: L10n.goBack,
                        size: .large,
                        style: .inverted,
                        expandable: true
                    ) {
                        onBack()
                    }
                }
            }
            .ignoresSafeArea()
            .background(
                Color(Asset.Colors.lime.color)
            )
        }
        .background(Color(Asset.Colors.lime.color))
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onClose()
                } label: {
                    Image(uiImage: UIImage.closeIcon)
                }
            }
        }
    }
}

struct ReAuthWrongAccount_Previews: PreviewProvider {
    static var previews: some View {
        ReAuthWrongAccountView(provider: .google, expectedEmail: "abc@gmail.com") {} onClose: {}
    }
}

private extension SocialProvider {
    var asString: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        }
    }
}
