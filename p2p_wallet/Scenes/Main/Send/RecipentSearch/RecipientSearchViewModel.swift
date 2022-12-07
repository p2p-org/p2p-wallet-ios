// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import History
import Resolver
import Send
import SolanaSwift

class RecipientSearchViewModel: ObservableObject {
    private let preChosenWallet: Wallet?
    private var subscriptions = Set<AnyCancellable>()

    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var tokensRepository: TokensRepository
    @Injected private var notificationService: NotificationService

    private let sendHistoryService: SendHistoryService
    private let recipientSearchService: RecipientSearchService
    private var searchTask: Task<Void, Never>?

    @Published var isFirstResponder: Bool = false

    @Published var input: String = ""
    @Published var searchResult: RecipientSearchResult? = nil
    @Published var userWalletEnvironments: UserWalletEnvironments = .empty

    @Published var isSearching = false
    private var autoSelectAfterSearch = false

    @Published var recipientsHistoryStatus: SendHistoryService.Status = .ready
    @Published var recipientsHistory: [Recipient] = []

    struct Coordinator {
        fileprivate let selectRecipientSubject: PassthroughSubject<Recipient, Never> = .init()
        var selectRecipientPublisher: AnyPublisher<Recipient, Never> { selectRecipientSubject.eraseToAnyPublisher() }

        fileprivate let scanQRSubject: PassthroughSubject<Void, Never> = .init()
        var scanQRPublisher: AnyPublisher<Void, Never> { scanQRSubject.eraseToAnyPublisher() }
    }

    let coordinator: Coordinator = .init()

    init(
        recipientSearchService: RecipientSearchService = Resolver.resolve(),
        sendHistoryService: SendHistoryService = Resolver.resolve(),
        preChosenWallet: Wallet?
    ) {
        self.recipientSearchService = recipientSearchService
        self.preChosenWallet = preChosenWallet
        self.sendHistoryService = sendHistoryService

        userWalletEnvironments = .init(
            wallets: walletsRepository.getWallets(),
            exchangeRate: [:],
            tokens: []
        )

        Task {
            let tokens = try await tokensRepository.getTokensList()
            await MainActor.run { [weak self] in
                self?.userWalletEnvironments = userWalletEnvironments.copy(
                    tokens: tokens
                )
            }
        }

        Task {
            let accountStreamSources = walletsRepository
                .getWallets()
                .reversed()
                .map { wallet in
                    AccountStreamSource(
                        account: wallet.pubkey ?? "",
                        symbol: wallet.token.symbol,
                        transactionRepository: SolanaTransactionRepository(solanaAPIClient: Resolver.resolve())
                    )
                }

            await self.sendHistoryService.synchronize(updateRemoteProvider: SendHistoryRemoteProvider(
                sourceStream: MultipleStreamSource(sources: accountStreamSources),
                historyTransactionParser: Resolver.resolve(),
                solanaAPIClient: Resolver.resolve(),
                nameService: Resolver.resolve()
            ))
        }

        sendHistoryService.statusPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] status in self?.recipientsHistoryStatus = status }
            .store(in: &subscriptions)

        sendHistoryService.recipientsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] recipients in self?.recipientsHistory = Array(recipients.prefix(10)) }
            .store(in: &subscriptions)

        $input
            .combineLatest($userWalletEnvironments)
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { [weak self] (query: String, env: UserWalletEnvironments) in
                self?.search(query: query, env: env)
            }.store(in: &subscriptions)
    }

    @MainActor
    func updateResult(result: RecipientSearchResult) {
        searchResult = result

        // Wait result and select first result
        if autoSelectAfterSearch {
            switch searchResult {
            case let .ok(recipients):
                if let recipient = recipients.first {
                    selectRecipient(recipient)
                    notifyAddressRecognized(recipient: recipient)
                }
            default:
                break
            }

            autoSelectAfterSearch = false
        }
    }

    func search(query: String, env: UserWalletEnvironments) {
        searchTask?.cancel()
        let currentSearchTerm = query.trimmingCharacters(in: .whitespaces)
        if currentSearchTerm.isEmpty {
            searchResult = nil
            isSearching = false
        } else {
            isSearching = true
            searchTask = Task {
                let result = await recipientSearchService.search(input: currentSearchTerm, env: userWalletEnvironments, preChosenToken: preChosenWallet?.token)

                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.isSearching = false
                }
                await updateResult(result: result)
            }
        }
    }

    @MainActor
    func past() {
        isFirstResponder = false
        guard let text = clipboardManager.stringFromClipboard() else { return }
        input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        notificationService.showToast(title: "✅", text: L10n.pastedFromClipboard)
    }

    @MainActor
    func qr() {
        isFirstResponder = false
        coordinator.scanQRSubject.send(())
    }

    func search(query: String, autoSelect: Bool = true) async {
        autoSelectAfterSearch = autoSelect
        search(query: query, env: userWalletEnvironments)
    }

    @MainActor
    func selectRecipient(_ recipient: Recipient) {
        coordinator.selectRecipientSubject.send(recipient)
    }

    @MainActor
    func notifyAddressRecognized(recipient: Recipient) {
        let text = L10n.theAddressIsRecognized("\(recipient.address.prefix(7))...\(recipient.address.suffix(7))")
        notificationService.showToast(title: "✅", text: text)
    }
}
