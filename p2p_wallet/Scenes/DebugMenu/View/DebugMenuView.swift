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
                    nameServiceEndpoint
                }
                
                featureTogglers
                
                application
                
                modules
                
                feeRelayer
            }
            .navigationBarTitle("Debug Menu", displayMode: .inline)
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
    }
    
    var modules: some View {
        Section(header: Text("Modules")) {
            NavigationLink("Socket", destination: SocketDebugView())
            NavigationLink("Web3Auth", destination: OnboardingDebugView())
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
}
