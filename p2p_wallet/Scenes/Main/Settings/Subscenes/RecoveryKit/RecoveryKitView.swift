// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

struct RecoveryKitView: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(spacing: 24) {
            VStack {
                Image(uiImage: .lockOutline)
                    .padding(.top, 12)
                Text(L10n.yourRecoveryKit)
                    .fontWeight(.bold)
                    .apply(style: .title2)
                    .padding(.top, 8)
                Text(L10n.IfYouSwitchDevicesYouCanEasilyRestoreYourWallet.noPrivateKeysNeeded)
                    .apply(style: .text2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
            .background(Color(Asset.Colors.lime.color))
            .cornerRadius(28)
            .padding(.top, safeAreaInsets.top + 50)

            RecoveryKitCell(title: L10n.seedPhrase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationTitle(L10n.seedPhraseDetails)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(Asset.Colors.cloud.color))
        .edgesIgnoringSafeArea(.top)
    }
}

struct RecoveryKitView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecoveryKitView()
        }
    }
}
