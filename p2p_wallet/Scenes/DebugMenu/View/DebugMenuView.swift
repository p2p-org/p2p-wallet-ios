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
                Group {
                    solanaEndpoint
                    swapEndpoint
                    strigaEndpoint
                    nameServiceEndpoint
                }
                
                socket

                featureTogglers

                application

                modules

                feeRelayer

                onboarding

                deviceShare
            }
            .navigationBarTitle("Debug Menu", displayMode: .inline)
        }
    }
    
    var socket: some View {
        Section(header: Text("Modules")) {
            NavigationLink("Socket", destination: SocketDebugView())
        }
    }
    
    var featureTogglers: some View {
        Section(header: Text("Feature Toggles")) {
            ForEach(0 ..< viewModel.features.count, id: \.self) { index in
                Toggle(viewModel.features[index].title, isOn: $viewModel.features[index].isOn)
                    .onChange(of: viewModel.features[index].isOn) { newValue in
                        viewModel.setFeature(viewModel.features[index].feature, isOn: newValue)
                    }
            }
        }
    }
    
    var application: some View {
        Section(header: Text("Application")) {
            TextFieldRow(title: "Wallet:", content: $globalAppState.forcedWalletAddress)
            TextFieldRow(title: "Push:", content: $globalAppState.pushServiceEndpoint)
            TextFieldRow(title: "Bridge:", content: $globalAppState.bridgeEndpoint)
            Toggle("Prefer direct swap", isOn: $globalAppState.preferDirectSwap)
            Button {
                Task {
                    ResolverScope.session.reset()
                    try await Resolver.resolve(UserWalletManager.self).refresh()
                    
                    // let app: AppEventHandlerType = Resolver.resolve()
                    // app.delegate?.refresh()
                }
            } label: { Text("Apply") }
        }
    }
    
    var modules: some View {
        Section(header: Text("Modules")) {
            NavigationLink("History") { HistoryDebugView() }
        }
    }
    
    var feeRelayer: some View {
        Section(header: Text("Fee relayer")) {
            Toggle("Disable free transaction", isOn: $feeRelayerConfig.disableFeeTransaction)
                .onChange(of: feeRelayerConfig.disableFeeTransaction) { _ in
                    let app: AppEventHandlerType = Resolver.resolve()
                    app.delegate?.refresh()
                }
            
            Picker("URL", selection: $globalAppState.forcedFeeRelayerEndpoint) {
                Text("Unknown").tag(nil as String?)
                ForEach(viewModel.feeRelayerEndpoints, id: \.self) { endpoint in
                    Text(endpoint).tag(endpoint as String?)
                }
            }
        }
    }
    
    var onboarding: some View {
        Section(header: Text("Onboarding configurations")) {
            TextFieldRow(title: "Torus:", content: $onboardingConfig.torusEndpoint)
            TextFieldRow(title: "OTP Resend", content: $onboardingConfig.enterOTPResend)
        }
    }
    
    var solanaEndpoint: some View {
        Section(header: Text("Solana endpoint")) {
            Text("Selected: \(viewModel.selectedEndpoint?.address ?? "Unknown")")
            Picker("URL", selection: $viewModel.selectedEndpoint) {
                Text("Unknown").tag(nil as APIEndPoint?)
                ForEach(viewModel.solanaEndpoints, id: \.self) { endpoint in
                    Text(endpoint.address).tag(endpoint as APIEndPoint?)
                }
            }
        }
    }
    
    var nameServiceEndpoint: some View {
        Section(header: Text("Name service")) {
            Picker("URL", selection: $globalAppState.nameServiceEndpoint) {
                Text("Unknown").tag(nil as String?)
                ForEach(viewModel.nameServiceEndpoints, id: \.self) { endpoint in
                    Text(endpoint).tag(endpoint as String?)
                }
            }
        }
    }
    
    var swapEndpoint: some View {
        Section(header: Text("New swap endpoint")) {
            Picker("URL", selection: $globalAppState.newSwapEndpoint) {
                Text("Unknown").tag(nil as String?)
                ForEach(viewModel.newSwapEndpoints, id: \.self) { endpoint in
                    Text(endpoint).tag(endpoint as String?)
                }
            }
        }
    }
    
    var strigaEndpoint: some View {
        Section(header: Text("Striga endpoint")) {
            Picker("URL", selection: $globalAppState.strigaEndpoint) {
                Text("Unknown").tag(nil as String?)
                ForEach(viewModel.strigaEndpoints, id: \.self) { endpoint in
                    Text(endpoint).tag(endpoint as String?)
                }
            }
            
            Toggle("Mocking enabled", isOn: $globalAppState.strigaMockingEnabled)
            
            Button {
                Resolver.resolve(KeychainStorage.self).metadataKeychain.clear()
                Resolver.resolve(NotificationService.self).showToast(title: "Deleted", text: "Metadata deleted from Keychain")
            } label: {
                Text("Delete metatdata from keychain")
            }
        }
    }
    
    var deviceShare: some View {
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
