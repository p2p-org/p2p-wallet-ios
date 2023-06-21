// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

struct OnboardingScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(Asset.Colors.lime.color))
            .edgesIgnoringSafeArea(.all)
            .frame(maxHeight: .infinity)
    }
}
