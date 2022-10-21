// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

class OnboardingConfig: ObservableObject {
    static let shared = OnboardingConfig()

    @Published var torusEndpoint: String
    @Published var torusGoogleVerifier: String
    @Published var torusGoogleSubVerifier: String
    @Published var torusAppleVerifier: String
    @Published var torusNetwork: String

    @Published var isDeviceShareMocked: Bool = false
    @Published var mockDeviceShare: String = ""

    @Published var enterOTPResend: String = "30,40,60,90,120"
    var enterOTPResendSteps: [Int] {
        enterOTPResend.split(separator: ",").map { Int($0) ?? 30 }
    }

    private init() {
        switch Environment.current {
        case .release:
            torusEndpoint = String.secretConfig("TORUS_ENDPOINT_PROD") ?? ""
            torusGoogleVerifier = String.secretConfig("TORUS_GOOGLE_VERIFIER_PROD") ?? ""
            torusGoogleSubVerifier = String.secretConfig("TORUS_GOOGLE_SUB_VERIFIER_PROD") ?? ""
            torusAppleVerifier = String.secretConfig("TORUS_APPLE_VERIFIER_PROD") ?? ""
            torusNetwork = String.secretConfig("TORUS_NETWORK_PROD") ?? ""
        default:
            torusEndpoint = String.secretConfig("TORUS_ENDPOINT_DEV") ?? ""
            torusGoogleVerifier = String.secretConfig("TORUS_GOOGLE_VERIFIER_DEV") ?? ""
            torusGoogleSubVerifier = String.secretConfig("TORUS_GOOGLE_SUB_VERIFIER_DEV") ?? ""
            torusAppleVerifier = String.secretConfig("TORUS_APPLE_VERIFIER_DEV") ?? ""
            torusNetwork = String.secretConfig("TORUS_NETWORK_DEV") ?? ""
        }
    }
}
