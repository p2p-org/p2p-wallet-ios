// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
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
                .styled(color: Asset.Colors.mountain)
            HStack(spacing: 2) {
                Text(L10n.termsOfService)
                    .underline(color: Color(Asset.Colors.snow.color))
                    .styled(color: Asset.Colors.snow)
                    .onTapGesture(perform: termsPressed)
                Text(L10n.and)
                    .styled(color: Asset.Colors.snow)
                Text(L10n.privacyPolicy)
                    .underline(color: Color(Asset.Colors.snow.color))
                    .styled(color: Asset.Colors.snow)
                    .onTapGesture(perform: privacyPolicyPressed)
            }
        }
    }
}

private extension Text {
    func styled(color: ColorAsset) -> some View {
        foregroundColor(Color(color.color))
            .font(.system(size: UIFont.fontSize(of: .label1)))
            .lineLimit(.none)
            .multilineTextAlignment(.center)
    }
}
