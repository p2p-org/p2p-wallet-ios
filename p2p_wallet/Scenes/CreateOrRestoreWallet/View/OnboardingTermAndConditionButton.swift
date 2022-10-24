// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

struct OnboardingTermAndConditionButton: View {
    let onPressed: () -> Void
    let isStart: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(isStart ? L10n.byContinuingYouAgreeToKeyAppS : L10n.keyAppS)
                .styled(color: Asset.Colors.mountain, font: .label1)
            Text(L10n.termsOfUseAndPrivacyPolicy)
                .styled(color: Asset.Colors.snow, font: .label1)
                .onTapGesture(perform: onPressed)
        }
    }
}

private extension Text {
    func styled(color: ColorAsset, font: UIFont.Style) -> some View {
        foregroundColor(Color(color.color))
            .font(.system(size: UIFont.fontSize(of: font)))
            .lineLimit(.none)
            .multilineTextAlignment(.center)
    }
}
