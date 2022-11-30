// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import History
import Resolver
import Send
import SolanaSwift

@MainActor
class RecipientSearchViewModel: ObservableObject {
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
        sendHistoryService: SendHistoryService = Resolver.resolve()
    ) {
        self.recipientSearchService = recipientSearchService
        self.sendHistoryService = sendHistoryService

        userWalletEnvironments = .init(
            wallets: walletsRepository.getWallets(),
            exchangeRate: [:],
            tokens: []
        )

        Task {
            self.userWalletEnvironments = userWalletEnvironments.copy(
                tokens: try await tokensRepository.getTokensList()
            )
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
            .sink { [weak self] status in self?.recipientsHistoryStatus = status }
            .store(in: &subscriptions)
        
        sendHistoryService.recipientsPublisher
            .sink { [weak self] recipients in self?.recipientsHistory = Array(recipients.prefix(10)) }
            .store(in: &subscriptions)

        $input
            .combineLatest($userWalletEnvironments)
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] (query: String, env: UserWalletEnvironments) in
                try await self?.search(query: query, env: env)
            }.store(in: &subscriptions)
    }

    func updateResult(result: RecipientSearchResult) {
        searchResult = result
    }

    func search(query: String, env _: UserWalletEnvironments) async throws {
        searchTask?.cancel()
        let currentSearchTerm = query.trimmingCharacters(in: .whitespaces)
        if currentSearchTerm.isEmpty {
            searchResult = nil
            isSearching = false
        } else {
            searchTask = Task {
                isSearching = true

                let result = await recipientSearchService.search(input: currentSearchTerm, env: userWalletEnvironments)

                if !Task.isCancelled {
                    isSearching = false
                } else {
                    return
                }

                self.searchResult = result
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

    func selectRecipient(_ recipient: Recipient) {
        coordinator.selectRecipientSubject.send(recipient)
    }
}
