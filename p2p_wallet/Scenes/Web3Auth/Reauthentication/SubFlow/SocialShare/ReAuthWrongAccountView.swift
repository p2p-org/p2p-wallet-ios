import Onboarding
import SwiftUI

struct ReAuthWrongAccountView: View {
    let provider: SocialProvider
    let selectedEmail: String

    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(data: .init(
                image: .womanNotFound,
                title: provider.title,
                subtitle: L10n.pleaseLogInWithTheCorrectAccount(selectedEmail, provider.body)
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
                Color(.lime)
            )
        }
        .background(Color(.lime))
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onClose()
                } label: {
                    Image(.closeIcon)
                }
            }
        }
    }
}

struct ReAuthWrongAccount_Previews: PreviewProvider {
    static var previews: some View {
        ReAuthWrongAccountView(provider: .google, selectedEmail: "abc@gmail.com") {} onClose: {}
    }
}

private extension SocialProvider {
    var title: String {
        switch self {
        case .apple: return "Incorrect Apple ID"
        case .google: return "Incorrect Google account"
        }
    }

    var body: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        }
    }
}
