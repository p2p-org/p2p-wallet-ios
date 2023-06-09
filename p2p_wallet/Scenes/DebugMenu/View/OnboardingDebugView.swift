//
//  OnboardingDebugView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.06.2023.
//

import Onboarding
import Resolver
import SwiftUI

class OnboardingViewModel: BaseViewModel, ObservableObject {
    @Injected var tkeyFacadeManager: TKeyFacadeManager

    @Published var tkeyInstance: String = "Init"
    @Published var ethAddressTkeyInstance: String = "Running"

    @Published var torusUserData: String = ""

    override init() {
        super.init()

        tkeyFacadeManager.latestPublisher.sink { [weak self] facade in
            if facade != nil {
                self?.tkeyInstance = "Running"
            } else {
                self?.tkeyInstance = "Nothing"
            }

            Task { [weak self] in
                self?.ethAddressTkeyInstance = await facade?.ethAddress ?? ""
            }

        }.store(in: &subscriptions)
    }

    func load() {
        Task {
            do {
                let userData = try await tkeyFacadeManager.latest?.getUserData()
                torusUserData = userData ?? "Nil"
            } catch {
                torusUserData = error.localizedDescription
            }
        }
    }
}

struct OnboardingDebugView: View {
    @StateObject var viewModel = OnboardingViewModel()
    @ObservedObject var onboardingConfig = OnboardingConfig.shared

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

            Section(header: Text("TKey")) {
                DebugText(title: "Status", value: viewModel.tkeyInstance)
                Button {
                    viewModel.load()
                } label: {
                    Text("Load")
                }
                DebugText(title: "User data", value: viewModel.torusUserData)
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
