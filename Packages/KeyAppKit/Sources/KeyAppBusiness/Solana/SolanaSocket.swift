//
//  AccountNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/07/2021.
//

import Foundation
import SolanaSwift
import Combine

public struct SolanaAccountEvent {
    public let pubkey: String
    public let lamports: Lamports
}

public protocol SolanaAccountsObservableService {
    var isConnected: Bool { get }
    func subscribeAccountNotification(account: String) async throws
    var allAccountsNotificcationsPublisher: AnyPublisher<SolanaAccountEvent, Never> { get }
}

private struct AccountObservableSubscribes {
    var requestID: String?
    var accountAddress: String?
    var subscribeID: UInt64?
}

public actor AccountObservableSubscribesManager {
    private var data: [AccountObservableSubscribes] = []

    func accept(account: String, id: String) {
        if let subscribeIndex = data.firstIndex(where: { $0.requestID == id }) {
            data[subscribeIndex].accountAddress = account
            return
        }
        data.append(.init(requestID: id, accountAddress: account))
    }

    func accept(socketId: UInt64, id: String) {
        if let subscribeIndex = data.firstIndex(where: { $0.requestID == id }) {
            data[subscribeIndex].subscribeID = socketId
            return
        }
        data.append(.init(requestID: id, subscribeID: socketId))
    }

    subscript(socketId: UInt64?) -> String? {
        data.first { $0.subscribeID == socketId }?.accountAddress
    }

    func contains(account: String) -> Bool {
        data.contains { subscribe in subscribe.accountAddress == account }
    }
}

public class SolananAccountsObservableServiceImpl: SolanaAccountsObservableService, SolanaSocketEventsDelegate {
    private var solanaSocket: SolanaSocket
    private let publisher: PassthroughSubject<SolanaAccountEvent, Never> = .init()
    private let subscribesManager: AccountObservableSubscribesManager = .init()

    public init(solanaSocket: SolanaSocket) {
        self.solanaSocket = solanaSocket
        self.solanaSocket.delegate = self
    }

    public var isConnected: Bool { solanaSocket.isConnected }

    public func subscribeAccountNotification(account: String) async throws {
        if #available(iOS 15.0, *), !isConnected {
            solanaSocket.connect()
        }
        if await subscribesManager.contains(account: account) { return }

        let id = try await solanaSocket.accountSubscribe(publickey: account, commitment: "finalized")
        await subscribesManager.accept(account: account, id: id)
    }

    public var allAccountsNotificcationsPublisher: AnyPublisher<SolanaAccountEvent, Never> {
        publisher.eraseToAnyPublisher()
    }

    public func nativeAccountNotification(notification: SocketNativeAccountNotification) {
        Task {
            guard
                let pubkey = await subscribesManager[notification.params?.subscription],
                let lamport = notification.lamports
            else { return }

            publisher.send(.init(pubkey: pubkey, lamports: lamport))
        }
    }

    public func tokenAccountNotification(notification: SocketTokenAccountNotification) {
        Task {
            guard
                let pubkey = await subscribesManager[notification.params?.subscription],
                let lamport: Lamports = Lamports(notification.params?.result?.value.data?.parsed.info.tokenAmount.amount ?? "")
            else { return }

            publisher.send(.init(pubkey: pubkey, lamports: lamport))
        }
    }

    public func subscribed(socketId: UInt64, id: String) {
        Task {
            await subscribesManager.accept(socketId: socketId, id: id)
        }
    }

    public func error(error _: Error?) {
        guard #available(iOS 15.0, *) else { return }
        solanaSocket.disconnect()
        solanaSocket.connect()
    }
}
