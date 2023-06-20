//
//  ReAuthSocialSignInView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import KeyAppUI
import SwiftUI

struct ReAuthSocialSignInView: View {
    @ObservedObject var viewModel: ReAuthSocialSignInViewModel

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(data: .init(
                image: .easyToStart,
                title: L10n.niceAlmostDone,
                subtitle: L10n.confirmAccessToYourAccountThatWasUsedToCreateTheWallet
            ))
            Spacer()
            BottomActionContainer {
                VStack(spacing: .zero) {
                    NewTextButton(
                        title: viewModel.buttonTitle,
                        size: .large,
                        style: .inverted,
                        expandable: true,
                        isLoading: viewModel.loading,
                        leading: .google
                    ) {
                        viewModel.signIn()
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
                Button() {
                    viewModel.close()
                } label: {
                    Image(uiImage: UIImage.closeIcon)
                }
            }
        }
    }
}

struct ReAuthSocialSignInView_Previews: PreviewProvider {
    static var previews: some View {
        ReAuthSocialSignInView(
            viewModel: .init(socialProvider: .google)
        )
    }
}
