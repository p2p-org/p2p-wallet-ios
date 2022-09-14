// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

class OnboardingConfig: ObservableObject {
    static let shared = OnboardingConfig()

    @Published var metaDataEndpoint: String = String.secretConfig("META_DATA_ENDPOINT") ?? ""
    @Published var torusEndpoint: String = String.secretConfig("TORUS_ENDPOINT") ?? ""
    @Published var torusGoogleVerifier: String = String.secretConfig("TORUS_GOOGLE_VERIFIER") ?? ""
    @Published var torusAppleVerifier: String = String.secretConfig("TORUS_APPLE_VERIFIER") ?? ""

    @Published var isDeviceShareMocked: Bool = false
    @Published var mockDeviceShare: String = ""

    @Published var enterOTPResend: String = "30,40,60,90,120"
    var enterOTPResendSteps: [Int] {
        enterOTPResend.split(separator: ",").map { Int($0) ?? 30 }
    }

    private init() {}
}
