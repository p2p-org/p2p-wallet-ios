// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import Onboarding

extension SocialProvider {
    var socialType: SocialType {
        switch self {
        case .apple:
            return .apple
        case .google:
            return .google
        }
    }
}

struct ReactiveProcess<T> {
    let data: T
    let finish: (Error?) -> Void

    func start(_ compute: @escaping () async throws -> Void) {
        Task {
            do {
                try await compute()
                finish(nil)
            } catch {
                finish(error)
            }
        }
    }
}
