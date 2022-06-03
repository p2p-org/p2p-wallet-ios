//
//  AccountNotificationsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/07/2021.
//

import Foundation
import RxSwift
import SolanaSwift

struct AccountsObservableEvent {
    let pubkey: String
    let lamports: Lamports
}

protocol AccountObservableService {
    var isConnected: Bool { get }
    func subscribeAccountNotification(account: String) async throws
    func observeAllAccountsNotifications() -> Observable<AccountsObservableEvent>
}

private struct AccountObservableSubscribes {
    var requestID: String?
    var accountAddress: String?
    var subscribeID: UInt64?
}

actor AccountObservableSubscribesManager {
    private var data: [AccountObservableSubscribes] = []

    func accept(account: String, id: String) {
        if var subscribe = data.first(where: { $0.requestID == id }) {
            subscribe.accountAddress = account
        }
        data.append(.init(requestID: id, accountAddress: account))
    }

    func accept(socketId: UInt64, id: String) {
        if var subscribe = data.first(where: { $0.requestID == id }) {
            subscribe.subscribeID = socketId
        }
        data.append(.init(requestID: id, subscribeID: socketId))
    }

    subscript(socketId: UInt64?) -> String? {
        data.first { $0.subscribeID == socketId }?.accountAddress
    }
}

class AccountsObservableServiceImpl: AccountObservableService, SolanaSocketEventsDelegate {
    private var solanaSocket: SolanaSocket
    private let publisher: PublishSubject<AccountsObservableEvent> = .init()
    private let subscribesManager: AccountObservableSubscribesManager = .init()

    init(solanaSocket: SolanaSocket) {
        self.solanaSocket = solanaSocket
        self.solanaSocket.delegate = self
    }

    var isConnected: Bool { solanaSocket.isConnected }

    func subscribeAccountNotification(account: String) async throws {
        if !isConnected { solanaSocket.connect() }

        let id = try await solanaSocket.accountSubscribe(publickey: account)
        await subscribesManager.accept(account: account, id: id)
    }

    func observeAllAccountsNotifications() -> Observable<AccountsObservableEvent> {
        publisher.asObservable()
    }

    func nativeAccountNotification(notification: SocketNativeAccountNotification) {
        Task {
            guard
                let pubkey = await subscribesManager[notification.params?.subscription],
                let lamport = notification.lamports
            else { return }

            publisher.on(.next(.init(pubkey: pubkey, lamports: lamport)))
        }
    }

    func tokenAccountNotification(notification: SocketTokenAccountNotification) {
        Task {
            guard
                let pubkey = await subscribesManager[notification.params?.subscription],
                let lamport = notification.result?.lamports
            else { return }

            publisher.on(.next(.init(pubkey: pubkey, lamports: lamport)))
        }
    }

    func subscribed(socketId: UInt64, id: String) {
        Task { await subscribesManager.accept(socketId: socketId, id: id) }
    }
}
