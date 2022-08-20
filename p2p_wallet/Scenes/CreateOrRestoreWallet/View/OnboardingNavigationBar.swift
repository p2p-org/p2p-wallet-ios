// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

extension View {
    func onboardingNavigationBar(
        title: String,
        onBack: (() -> Void)? = nil,
        onInfo: (() -> Void)? = nil
    ) -> some View {
        navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(
                leading: onBack != nil ? Button(
                    action: { onBack?() },
                    label: {
                        Image(uiImage: Asset.MaterialIcon.arrowBackIos.image)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    }
                ) : nil,
                trailing: onInfo != nil ? Button(
                    action: { onInfo?() },
                    label: {
                        Image(uiImage: Asset.MaterialIcon.helpOutline.image)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    }
                ) : nil
            )
    }
}
