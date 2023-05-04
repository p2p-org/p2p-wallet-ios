//
//  File.swift
//
//
//  Created by Giang Long Tran on 03.05.2023.
//

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

    public static func == (lhs: RealtimeSolanaAccountState, rhs: RealtimeSolanaAccountState) -> Bool {
        switch (lhs, rhs) {
        case (.initialising, initialising):
            return true
        case (.connecting, connecting):
            return true
        case (.running, running):
            return true
        case let (.stop(lhsError), stop(rhsError)):
            return (lhsError as? NSError) == (rhsError as? NSError)
        default:
            return false
        }
    }
}

public protocol RealtimeSolanaAccountService {
    var owner: String { get }

    var update: AnyPublisher<SolanaAccount, Never> { get }
    var state: RealtimeSolanaAccountState { get }

    func connect()
}

class RealtimeSolanaAccountServiceImpl: RealtimeSolanaAccountService {
    var owner: String

    let apiClient: SolanaAPIClient
    let tokensService: SolanaTokensRepository
    let errorObserver: ErrorObserver

    var accountsSubject: PassthroughSubject<SolanaAccount, Never> = .init()

    var update: AnyPublisher<SolanaAccount, Never> {
        accountsSubject.eraseToAnyPublisher()
    }

    var state: RealtimeSolanaAccountState = .initialising

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)

    let solanaWebSocketMethod: SolanaWebSocketMethods = .init()

    init(
        owner: String,
        apiClient: SolanaAPIClient,
        tokensService: SolanaTokensRepository,
        errorObserver: ErrorObserver
    ) {
        self.owner = owner
        self.apiClient = apiClient
        self.tokensService = tokensService
        self.errorObserver = errorObserver
    }

    deinit {
        // Close socket
        _ = ws?.close()
    }

    /// Websocket event loop
    var ws: WebSocket?

    /// Start web socket
    func connect() {
        _ = ws?.close()

        print("RealtimeSolanaAccountService", apiClient.endpoint.socketUrl)

        _ = WebSocket.connect(
            to: apiClient.endpoint.socketUrl,
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
                print("RealtimeSolanaAccountService Response", dataStr)
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
                            self?.receiveNotification(notification: request.params)
                        }
                    }
                } catch {
                    print("RealtimeSolanaAccountService Response", error)
                    errorObserver.handleError(error)
                }
            }
        }
    }

    /// Accept new state that service emit from base on ws.
    func acceptState(
        _ ws: WebSocket,
        _ prevState: RealtimeSolanaAccountState,
        _ nextState: RealtimeSolanaAccountState
    ) {
        print("RealtimeSolanaAccountService", nextState)
        state = nextState

        switch nextState {
        case .initialising:
            break

        case .connecting:
            break

        case .running:
            if prevState != .initialising {
                getLatestAccountsState()
            }

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

            print("RealtimeSolanaAccountService", String(data: nativeAccountChangeRequest, encoding: .utf8))
            print("RealtimeSolanaAccountService", String(data: splAccountChangeRequest, encoding: .utf8))

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
                // TODO: Need to optimize
                let (balance, splAccounts) = try await(
                    apiClient.getBalance(account: owner, commitment: "confirmed"),
                    apiClient.getTokenWallets(account: owner, tokensRepository: tokensService, commitment: "confirmed")
                )

                if Task.isCancelled { return }

                let solanaAccount = SolanaAccount(
                    data: Wallet.nativeSolana(
                        pubkey: owner,
                        lamport: balance
                    )
                )

                let accounts = [solanaAccount] + splAccounts.map { SolanaAccount(data: $0, price: nil) }

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

        let account = value.account
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
                    let tokenAccountData = try AccountInfo(from: &reader)

                    // Bad code because of O(n)
                    let tokens = try await tokensService.getTokensList(useCache: true)
                    let token = tokens.first { $0.address == tokenAccountData.mint.base58EncodedString }

                    // TODO: Add case when token info is invalid
                    if let token {
                        let wallet = SolanaSwift.Wallet(
                            pubkey: pubKey,
                            lamports: tokenAccountData.lamports,
                            supply: nil,
                            token: token
                        )

                        let splAccount = SolanaAccount(data: wallet)
                        accountsSubject.send(splAccount)
                    }

                } catch {
                    print("RealtimeSolanaAccountService", error)
                    errorObserver.handleError(error)
                }
            }
        }
    }

    func receiveNotification(notification: SolanaNotification<SolanaAccountChange>) {
        let wallet = SolanaSwift.Wallet(
            pubkey: owner,
            lamports: notification.result.value.lamports,
            supply: nil,
            token: .nativeSolana
        )

        let nativeSolanaAccount = SolanaAccount(data: wallet)
        accountsSubject.send(nativeSolanaAccount)
    }
}
