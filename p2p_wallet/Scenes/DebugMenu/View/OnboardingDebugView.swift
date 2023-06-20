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
    @Injected var userWalletManager: UserWalletManager
    @Injected var remoteWalletMetadataProvider: RemoteWalletMetadataProvider
    @Injected var localWalletMetadataProvider: LocalWalletMetadataProvider

    @Published var tkeyInstance: String = "Init"
    @Published var ethAddressTkeyInstance: String = "Running"

    @Published var torusUserData: String = ""
    @Published var remoteMetadata: String = ""
    @Published var localMetadata: String = ""

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

    func loadRemoteMetadata() {
        Task {
            guard let user = userWalletManager.wallet else {
                return
            }
            let data = try await remoteWalletMetadataProvider.load(for: user)
            remoteMetadata = data?.jsonString ?? "nil"
        }
    }

    func loadLocalMetadata() {
        Task {
            guard let user = userWalletManager.wallet else {
                return
            }
            let data = try await localWalletMetadataProvider.load(for: user)
            localMetadata = data?.jsonString ?? "nil"
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

            Section(header: Text("TKey metadata")) {
                DebugText(title: "Status", value: viewModel.tkeyInstance)
                Button {
                    viewModel.load()
                } label: {
                    Text("Load")
                }
                if !viewModel.torusUserData.isEmpty {
                    DebugText(title: nil, value: viewModel.torusUserData)
                }
            }

            Section(header: Text("Local Metadata")) {
                Button {
                    viewModel.loadLocalMetadata()
                } label: {
                    Text("Load local metadata")
                }

                if !viewModel.localMetadata.isEmpty {
                    DebugText(title: nil, value: viewModel.localMetadata)
                }
            }

            Section(header: Text("Remote Metadata")) {
                Button {
                    viewModel.loadRemoteMetadata()
                } label: {
                    Text("Load remote metadata")
                }

                if !viewModel.remoteMetadata.isEmpty {
                    DebugText(title: nil, value: viewModel.remoteMetadata)
                }
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
