//
//  DebugMenuView.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import Resolver
import SolanaSwift
import SwiftUI

struct DebugMenuView: View {
    @ObservedObject private var viewModel: DebugMenuViewModel
    
    @ObservedObject private var globalAppState = GlobalAppState.shared
    @ObservedObject private var feeRelayerConfig = FeeRelayConfig.shared
    @ObservedObject private var onboardingConfig = OnboardingConfig.shared

    init(viewModel: DebugMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            List {
                Toggle("Network Logger", isOn: $viewModel.networkLoggerVisible)
                Section(header: Text("Feature Toggles")) {
                    ForEach(0 ..< viewModel.features.count, id: \.self) { index in
                        if let feature = viewModel.features[index].feature {
                            Toggle(viewModel.features[index].title, isOn: $viewModel.features[index].isOn)
                                .valueChanged(value: viewModel.features[index].isOn) { newValue in
                                    viewModel.setFeature(feature, isOn: newValue)
                                }
                        } else {
                            Text(viewModel.features[index].title)
                        }
                    }
                }
                Section(header: Text("Application")) {
                    TextFieldRow(title: "Wallet:", content: $globalAppState.forcedWalletAddress)
                    Button {
                        Task {
                            #if DEBUG
                                showDebugger(false)
                            #endif
                            
                            try await Resolver.resolve(UserWalletManager.self).refresh()
                            
//                            let app: AppEventHandlerType = Resolver.resolve()
//                            app.delegate?.refresh()
                        }
                    } label: { Text("Apply") }
                }
                
                Section(header: Text("Fee relayer")) {
                    Toggle("Disable free transaction", isOn: $feeRelayerConfig.disableFeeTransaction)
                        .valueChanged(value: feeRelayerConfig.disableFeeTransaction) { newValue in
                            #if DEBUG
                            showDebugger(false)
                            #endif
                            
                            let app: AppEventHandlerType = Resolver.resolve()
                            app.delegate?.refresh()
                        }
                }

                Section(header: Text("Onboarding configurations")) {
                    TextFieldRow(title: "Torus:", content: $onboardingConfig.torusEndpoint)
                    TextFieldRow(title: "Google:", content: $onboardingConfig.torusGoogleVerifier)
                    TextFieldRow(title: "Apple", content: $onboardingConfig.torusAppleVerifier)
                    TextFieldRow(title: "OTP Resend", content: $onboardingConfig.enterOTPResend)
                }

                Section(header: Text("Solana endpoint")) {
                    Text("Selected: \(viewModel.selectedEndpoint?.address ?? "Unknown")")
                    Picker("URL", selection: $viewModel.selectedEndpoint) {
                        Text("Unknown").tag(nil as APIEndPoint?)
                        ForEach(viewModel.solanaEndpoints, id: \.self) { endpoint in
                            Text(endpoint.address).tag(endpoint as APIEndPoint?)
                        }
                    }
                }

                Section(header: Text("Mocked device share")) {
                    Toggle("Enabled", isOn: $onboardingConfig.isDeviceShareMocked)
                        .valueChanged(value: onboardingConfig.isDeviceShareMocked) { newValue in
                            onboardingConfig.isDeviceShareMocked = newValue
                        }
                    TextFieldRow(title: "Share:", content: $onboardingConfig.mockDeviceShare)
                        .disabled(!onboardingConfig.isDeviceShareMocked)
                        .foregroundColor(!onboardingConfig.isDeviceShareMocked ? Color.gray : Color.black)

                    HStack {
                        Text("Delete current share")
                        Spacer()
                        Button {
                            do {
                                try Resolver.resolve(KeychainStorage.self).save(deviceShare: "")
                            } catch { print(error) }
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
            }
            .navigationBarTitle("Debug Menu", displayMode: .inline)
        }
    }
}

private struct TextFieldRow: View {
    let title: String
    let content: Binding<String>

    var body: some View {
        HStack {
            Text(title)
            TextEditor(text: content)
        }
    }
}
