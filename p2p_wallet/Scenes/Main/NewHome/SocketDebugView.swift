//
//  SocketDebugView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.05.2023.
//

import Combine
import KeyAppBusiness
import Resolver
import SwiftUI

class SocketDebugViewModel: ObservableObject {
    var subscriptions: [AnyCancellable] = []

    @Published var status: RealtimeSolanaAccountState = .initialising

    @Published var proxyHost: String = ""
    @Published var proxyPort: String = ""

    init() {
        let solanaAccountService: SolanaAccountsService = Resolver.resolve()
        solanaAccountService
            .realtimeService?
            .statePublisher
            .assignWeak(to: \.status, on: self)
            .store(in: &subscriptions)
    }

    func reconnect() {
        let solanaAccountService: SolanaAccountsService = Resolver.resolve()

        let proxy: ProxyConfiguration?
        if !proxyHost.isEmpty {
            proxy = .init(address: proxyHost, port: Int(proxyPort) ?? nil)
        } else {
            proxy = nil
        }

        solanaAccountService.realtimeService?.reconnect(with: proxy)
    }
}

extension SocketDebugViewModel {
    class Monitor: ObservableObject {
        var subscriptions: [AnyCancellable] = []

        struct Record: Identifiable {
            let id: String = UUID().uuidString
            var state: RealtimeSolanaAccountState
            var date: Date = .init()
        }

        @Published var history: [Record] = []

        static let shared = Monitor()

        func start() {
            let solanaAccountService: SolanaAccountsService = Resolver.resolve()
            solanaAccountService
                .realtimeService?
                .statePublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] state in self?.history.insert(.init(state: state), at: 0) }
                .store(in: &subscriptions)
        }

        func stop() {
            subscriptions = []
        }

        func clear() {
            history = []
        }
    }
}

struct SocketDebugView: View {
    @ObservedObject var viewModel: SocketDebugViewModel = .init()

    var body: some View {
        List {
            Section(header: Text("Status")) {
                Text(viewModel.status.rawString)
                if case let .stop(error) = viewModel.status {
                    Text(error?.localizedDescription)
                }
            }

            Section(header: Text("Proxy")) {
                TextField("Host", text: $viewModel.proxyHost)
                TextField("Port", text: $viewModel.proxyPort)
                Button { viewModel.reconnect() } label: { Text("Reconnect") }
            }

            Section(header: Text("Actions")) {
                Button { SocketDebugViewModel.Monitor.shared.start() } label: { Text("Record") }
                Button { SocketDebugViewModel.Monitor.shared.stop() } label: { Text("Stop") }
                Button { SocketDebugViewModel.Monitor.shared.clear() } label: { Text("Clean") }
            }

            Section(header: Text("History")) {
                ForEach(SocketDebugViewModel.Monitor.shared.history) { record in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(record.state.rawString)
                            Spacer()
                            Text(record.date.string(withFormat: "MMMM,yyyy HH:mm:ss"))
                        }
                        if case let .stop(error) = record.state {
                            Text(error?.localizedDescription)
                        }
                    }
                }
            }
        }
    }
}

struct SocketDebugView_Previews: PreviewProvider {
    static var previews: some View {
        SocketDebugView()
    }
}
