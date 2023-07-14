import KeyAppUI
import Onboarding
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
                        title: viewModel.provider.title,
                        size: .large,
                        style: .inverted,
                        expandable: true,
                        isLoading: viewModel.loading,
                        leading: viewModel.provider.image
                    ) {
                        viewModel.signIn()
                    }
                }
            }
            .ignoresSafeArea()
            .background(
                Color(.lime)
            )
        }
        .background(Color(.lime))
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.close()
                } label: {
                    Image(.closeIcon)
                }
            }
        }
    }
}

private extension SocialProvider {
    var title: String {
        switch self {
        case .apple:
            return L10n.continueWithApple
        case .google:
            return L10n.continueWithGoogle
        }
    }

    var image: UIImage {
        switch self {
        case .apple:
            return .init(resource: .appleLogo).withTintColor(.black)
        case .google:
            return .init(resource: .google)
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
