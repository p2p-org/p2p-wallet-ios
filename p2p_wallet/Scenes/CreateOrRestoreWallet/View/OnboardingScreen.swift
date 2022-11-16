// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

extension View {
    func onboardingScreen() -> some View {
        background(Color(Asset.Colors.lime.color))
            .edgesIgnoringSafeArea(.all)
            .frame(maxHeight: .infinity)
    }
}
