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

    init(viewModel: DebugMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Modules")) {
                    NavigationLink("Socket", destination: SocketDebugView())
                    NavigationLink("Web3Auth", destination: OnboardingDebugView())
                }

                Section(header: Text("Feature Toggles")) {
                    ForEach(0 ..< viewModel.features.count, id: \.self) { index in
                        Toggle(viewModel.features[index].title, isOn: $viewModel.features[index].isOn)
                            .valueChanged(value: viewModel.features[index].isOn) { newValue in
                                viewModel.setFeature(viewModel.features[index].feature, isOn: newValue)
                            }
                    }
                }

                Section(header: Text("Application")) {
                    DebugTextField(title: "Wallet:", content: $globalAppState.forcedWalletAddress)
                    DebugTextField(title: "Push:", content: $globalAppState.pushServiceEndpoint)
                    DebugTextField(title: "Bridge:", content: $globalAppState.bridgeEndpoint)
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

                Section(header: Text("Modules")) {
                    NavigationLink("History") { HistoryDebugView() }
                }

                Section(header: Text("Fee relayer")) {
                    Toggle("Disable free transaction", isOn: $feeRelayerConfig.disableFeeTransaction)
                        .valueChanged(value: feeRelayerConfig.disableFeeTransaction) { _ in
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

                Section(header: Text("Solana endpoint")) {
                    Text("Selected: \(viewModel.selectedEndpoint?.address ?? "Unknown")")
                    Picker("URL", selection: $viewModel.selectedEndpoint) {
                        Text("Unknown").tag(nil as APIEndPoint?)
                        ForEach(viewModel.solanaEndpoints, id: \.self) { endpoint in
                            Text(endpoint.address).tag(endpoint as APIEndPoint?)
                        }
                    }
                }

                Section(header: Text("Name service")) {
                    Picker("URL", selection: $globalAppState.nameServiceEndpoint) {
                        Text("Unknown").tag(nil as String?)
                        ForEach(viewModel.nameServiceEndpoints, id: \.self) { endpoint in
                            Text(endpoint).tag(endpoint as String?)
                        }
                    }
                }

                Section(header: Text("New swap endpoint")) {
                    Picker("URL", selection: $globalAppState.newSwapEndpoint) {
                        Text("Unknown").tag(nil as String?)
                        ForEach(viewModel.newSwapEndpoints, id: \.self) { endpoint in
                            Text(endpoint).tag(endpoint as String?)
                        }
                    }
                }
            }
            .navigationBarTitle("Debug Menu", displayMode: .inline)
        }
    }
}
