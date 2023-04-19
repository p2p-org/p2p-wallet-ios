// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import History
import NameService
import SolanaSwift
import TransactionParser

public protocol SendHistoryProvider {
    func getRecipients() async throws -> [Recipient]?
    func save(_ recipients: [Recipient]?) async throws
}

public class SendHistoryService: ObservableObject {
    public enum Status {
        case initializing
        case ready
        case synchronizing
    }

    private let statusSubject: CurrentValueSubject<Status, Never> = .init(.ready)
    public var statusPublisher: AnyPublisher<Status, Never> { statusSubject.eraseToAnyPublisher() }

    private let recipientsSubject: CurrentValueSubject<[Recipient], Never> = .init([])
    public var recipientsPublisher: AnyPublisher<[Recipient], Never> { recipientsSubject.eraseToAnyPublisher() }

    private let errorSubject: CurrentValueSubject<Error?, Never> = .init(nil)
    public var errorPublisher: AnyPublisher<Error?, Never> { errorSubject.eraseToAnyPublisher() }

    private let provider: SendHistoryProvider

    public init(provider: SendHistoryProvider) {
        self.provider = provider

        Task { await initialize() }
    }

    public func initialize() async {
        do {
            statusSubject.send(.initializing)
            defer { statusSubject.send(.ready) }

            guard let recipients = try await provider.getRecipients() else { return }
            recipientsSubject.send(recipients)
        } catch {
            debugPrint(error)
            errorSubject.send(error)
        }
    }

    public func insert(_ newRecipient: Recipient) async throws {
        var newList = recipientsSubject.value

        if let index = newList.firstIndex(where: { (recipient: Recipient) -> Bool in recipient.id == newRecipient.id }) {
            newList.remove(at: index)
        }

        newList.insert(newRecipient.copy(createdData: Date()), at: 0)
        newList = Array(newList.prefix(10))

        try await provider.save(Array(newList))

        recipientsSubject.send(newList)
    }
}
