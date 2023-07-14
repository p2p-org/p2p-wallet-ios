import SwiftUI

struct OnboardingTermsAndPolicyButton: View {
    let termsPressed: () -> Void
    let privacyPolicyPressed: () -> Void
    let termsText: String

    init(termsPressed: @escaping () -> Void, privacyPolicyPressed: @escaping () -> Void, termsText: String = L10n.keyAppS) {
        self.termsPressed = termsPressed
        self.privacyPolicyPressed = privacyPolicyPressed
        self.termsText = termsText
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(termsText)
                .styled(color: .mountain)
            HStack(spacing: 2) {
                Text(L10n.termsOfService)
                    .underline(color: Color(.snow))
                    .styled(color: .snow)
                    .onTapGesture(perform: termsPressed)
                Text(L10n.and)
                    .styled(color: .snow)
                Text(L10n.privacyPolicy)
                    .underline(color: Color(.snow))
                    .styled(color: .snow)
                    .onTapGesture(perform: privacyPolicyPressed)
            }
        }
    }
}

private extension Text {
    func styled(color: ColorResource) -> some View {
        foregroundColor(Color(color))
            .font(.system(size: UIFont.fontSize(of: .label1)))
            .lineLimit(.none)
            .multilineTextAlignment(.center)
    }
}
