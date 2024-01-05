import Combine
import Foundation
import KeyAppKitCore
import NIO
import SolanaSwift
import WebSocketKit

public enum RealtimeSolanaAccountState: Equatable {
    case initialising
    case connecting
    case running
    case stop(error: Error?)

    public var rawString: String {
        switch self {
        case .initialising: return "Initialising"
        case .connecting: return "Connecting"
        case .running: return "Running"
        case .stop: return "Stop"
        }
    }

    public static func == (lhs: RealtimeSolanaAccountState, rhs: RealtimeSolanaAccountState) -> Bool {
        switch (lhs, rhs) {
        case (.initialising, initialising):
            return true
        case (.connecting, connecting):
            return true
        case (.running, running):
            return true
        case (.stop, stop):
            return true
        default:
            return false
        }
    }
}

public protocol RealtimeSolanaAccountService {
    var owner: String { get }

    var update: AnyPublisher<SolanaAccount, Never> { get }

    var state: RealtimeSolanaAccountState { get }
    var statePublisher: AnyPublisher<RealtimeSolanaAccountState, Never> { get }

    func reconnect(with proxy: ProxyConfiguration?)
    func connect()
}

final class RealtimeSolanaAccountServiceImpl: RealtimeSolanaAccountService {
    let owner: String

    let apiClient: SolanaAPIClient
    let tokensService: SolanaTokensService
    var proxyConfiguration: ProxyConfiguration?
    let errorObserver: ErrorObserver

    var accountsSubject: PassthroughSubject<SolanaAccount, Never> = .init()

    var update: AnyPublisher<SolanaAccount, Never> {
        accountsSubject.eraseToAnyPublisher()
    }

    var stateSubject: CurrentValueSubject<RealtimeSolanaAccountState, Never> = .init(.initialising)

    var statePublisher: AnyPublisher<RealtimeSolanaAccountState, Never> { stateSubject.eraseToAnyPublisher() }

    var state: RealtimeSolanaAccountState { stateSubject.value }

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)

    let solanaWebSocketMethod = SolanaWebSocketMethods()

    init(
        owner: String,
        apiClient: SolanaAPIClient,
        tokensService: SolanaTokensService,
        proxyConfiguration: ProxyConfiguration?,
        errorObserver: ErrorObserver
    ) {
        self.owner = owner
        self.apiClient = apiClient
        self.tokensService = tokensService
        self.proxyConfiguration = proxyConfiguration
        self.errorObserver = errorObserver
    }

    deinit {
        // Close socket
        _ = ws?.close()
    }

    func reconnect(with proxy: ProxyConfiguration?) {
        _ = ws?.close()

        proxyConfiguration = proxy
        connect()
    }

    /// Websocket event loop
    var ws: WebSocket?

    /// Start web socket
    func connect() {
        if let ws, ws.isClosed == false {
            return
        }

        _ = ws?.close()

        let connecting = WebSocket.connect(
            to: apiClient.endpoint.socketUrl,
            proxy: proxyConfiguration?.address,
            proxyPort: proxyConfiguration?.port,
            on: eventLoopGroup
        ) { [weak self, errorObserver] ws in
            self?.ws = ws

            // Set ping interval and timeout.
            ws.pingInterval = .seconds(10)

            if let self {
                self.acceptState(ws, self.state, .running)
            }

            // Listen failure
            ws.onClose.whenComplete { result in
                guard let self else { return }
                switch result {
                case .success:
                    self.acceptState(ws, self.state, .stop(error: nil))
                case let .failure(error):
                    self.acceptState(ws, self.state, .stop(error: error))
                }
            }

            // Listen response
            let decoder = JSONDecoder()
            ws.onText { _, dataStr in
                // Quick workaround
                guard dataStr.contains("accountNotification") || dataStr.contains("programNotification") else { return }

                do {
                    if dataStr.contains("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA") {
                        // Token account did change
                        let requestType = JSONRPCRequest<SolanaNotification<SolanaProgramChange>>.self
                        if let data = dataStr.data(using: .utf8) {
                            let request = try decoder.decode(requestType, from: data)
                            self?.receiveNotification(notification: request.params)
                        }

                    } else if dataStr.contains("11111111111111111111111111111111") {
                        let requestType = JSONRPCRequest<SolanaNotification<SolanaAccountChange>>.self
                        if let data = dataStr.data(using: .utf8) {
                            let request = try decoder.decode(requestType, from: data)
                            try await self?.receiveNotification(notification: request.params)
                        }
                    }
                } catch {
                    errorObserver.handleError(error)
                }
            }
        }

        connecting.whenComplete { [weak self] result in
            switch result {
            case .success:
                return
            case let .failure(error):
                guard let self else { return }
                self.acceptState(nil, self.state, .stop(error: error))
            }
        }
    }

    /// Accept new state that service emit from base on ws.
    func acceptState(
        _ ws: WebSocket?,
        _ prevState: RealtimeSolanaAccountState,
        _ nextState: RealtimeSolanaAccountState
    ) {
        stateSubject.send(nextState)

        switch nextState {
        case .initialising:
            break

        case .connecting:
            break

        case .running:
            if prevState != .initialising {
                getLatestAccountsState()
            }

            guard let ws else { return }
            let error = subscribeEvents(ws: ws)
            if let error {
                acceptState(ws, .running, .stop(error: error))
            }

        case let .stop(error: error):
            // Report
            if let error {
                errorObserver.handleError(error)
            }

            // Update latest states
            getLatestAccountsState()

            // Rerun in 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                self?.connect()
            }
        }
    }

    func subscribeEvents(ws: WebSocket) -> Error? {
        do {
            let nativeAccountChange = solanaWebSocketMethod.accountSubscribe(
                account: owner,
                commitment: "confirmed",
                encoding: "base64"
            )

            let splAccountChange = solanaWebSocketMethod.programSubscribe(
                program: TokenProgram.id.base58EncodedString,
                commitment: "confirmed",
                encoding: "base64",
                filters: [
                    [
                        "dataSize": 165,
                    ],
                    [
                        "memcmp": [
                            "offset": 32,
                            "bytes": owner,
                        ] as [String: Any],
                    ],
                ]
            )

            let nativeAccountChangeRequest = try JSONSerialization.data(withJSONObject: nativeAccountChange)
            let splAccountChangeRequest = try JSONSerialization.data(withJSONObject: splAccountChange)

            ws.send(nativeAccountChangeRequest.bytes)
            ws.send(splAccountChangeRequest.bytes)

            return nil
        } catch {
            errorObserver.handleError(error)
            return error
        }
    }

    /// Current running task for fetching latest account state
    var getLatestAccountsStateTask: Task<Void, Error>?

    /// Get all latests account state for given owner.
    func getLatestAccountsState() {
        getLatestAccountsStateTask?.cancel()
        getLatestAccountsStateTask = Task {
            do {
                // Updating native account balance and get spl tokens
                let (balance, (resolved, _)) = try await(
                    apiClient.getBalance(account: owner, commitment: "confirmed"),
                    apiClient.getAccountBalancesWithToken2022(
                        for: owner,
                        tokensRepository: tokensService,
                        commitment: "confirmed"
                    )
                )

                if Task.isCancelled { return }

                let solanaAccount = try SolanaAccount(
                    address: owner,
                    lamports: balance,
                    token: await tokensService.nativeToken
                )

                let accounts = [solanaAccount] + resolved
                    .map { accountBalance in
                        guard let pubKey = accountBalance.pubkey else {
                            return nil
                        }

                        return SolanaAccount(
                            address: pubKey,
                            lamports: accountBalance.lamports ?? 0,
                            token: accountBalance.token
                        )
                    }
                    .compactMap { $0 }

                for account in accounts {
                    accountsSubject.send(account)
                }
            } catch {
                errorObserver.handleError(error)
            }
        }
    }

    func receiveNotification(notification: SolanaNotification<SolanaProgramChange>) {
        let value = notification.result.value

        let dataStr = value.account.data.first

        if let dataStr, !dataStr.isEmpty {
            // SPL Token Account Data
            Task {
                do {
                    guard let pubKey = value.pubkey else { return }

                    // Convert to Data
                    guard let data = Data(base64Encoded: dataStr) else {
                        return
                    }

                    // Parse
                    var reader = BinaryReader(bytes: data.bytes)
                    let tokenAccountData = try SPLTokenAccountState(from: &reader)

                    // Get token
                    let token = try await tokensService.get(address: tokenAccountData.mint)

                    // TODO: Add case when token info is invalid
                    if let token {
                        let splAccount = SolanaAccount(
                            address: pubKey,
                            lamports: tokenAccountData.lamports,
                            token: token
                        )
                        accountsSubject.send(splAccount)
                    }

                } catch {
                    errorObserver.handleError(error)
                }
            }
        }
    }

    func receiveNotification(notification: SolanaNotification<SolanaAccountChange>) async throws {
        let nativeSolanaAccount = try SolanaAccount(
            address: owner,
            lamports: notification.result.value.lamports,
            token: await tokensService.nativeToken
        )
        accountsSubject.send(nativeSolanaAccount)
    }
}
