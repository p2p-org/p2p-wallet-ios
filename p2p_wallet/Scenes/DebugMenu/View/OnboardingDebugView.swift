//
//  OnboardingDebugView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.06.2023.
//

import Resolver
import SwiftUI

struct OnboardingDebugView: View {
    @ObservedObject private var onboardingConfig = OnboardingConfig.shared

    var body: some View {
        List {
            Section(header: Text("Info")) {
                DebugText(title: "Network", value: onboardingConfig.torusNetwork)
                DebugText(title: "GG Verifier", value: onboardingConfig.torusGoogleVerifier)
                DebugText(title: "GG Subverifier", value: onboardingConfig.torusGoogleSubVerifier)
                DebugText(title: "AP Verifier", value: onboardingConfig.torusAppleVerifier)
            }

            Section(header: Text("Onboarding configurations")) {
                DebugTextField(title: "Torus:", content: $onboardingConfig.torusEndpoint)
                DebugTextField(title: "OTP Resend", content: $onboardingConfig.enterOTPResend)
            }

            Section(header: Text("Mocked device share")) {
                Toggle("Enabled", isOn: $onboardingConfig.isDeviceShareMocked)
                    .valueChanged(value: onboardingConfig.isDeviceShareMocked) { newValue in
                        onboardingConfig.isDeviceShareMocked = newValue
                    }
                DebugTextField(title: "Share:", content: $onboardingConfig.mockDeviceShare)
                    .disabled(!onboardingConfig.isDeviceShareMocked)
                    .foregroundColor(!onboardingConfig.isDeviceShareMocked ? Color.gray : Color.black)

                HStack {
                    Text("Delete current share")
                    Spacer()
                    Button {
                        Resolver.resolve(DeviceShareManager.self).save(deviceShare: "")
                    } label: { Text("Delete") }
                }

                HStack {
                    Text("Delete last progress")
                    Spacer()
                    Button {
                        Resolver.resolve(OnboardingService.self).lastState = nil
                    } label: { Text("Delete") }
                }
            }
        }.navigationTitle("Web3Auth")
    }
}

struct OnboardingDebugView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingDebugView()
    }
}
