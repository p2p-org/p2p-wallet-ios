// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Onboarding

extension SignInProvider {
    var socialType: SocialType {
        switch self {
        case .apple:
            return .apple
        case .google:
            return .google
        }
    }
}
