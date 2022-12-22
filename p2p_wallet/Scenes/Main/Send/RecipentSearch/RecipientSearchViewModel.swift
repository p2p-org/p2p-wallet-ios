// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import AnalyticsManager
import Combine
import Foundation
import History
import Resolver
import Send
import SolanaSwift

class RecipientSearchViewModel: ObservableObject {
    private let preChosenWallet: Wallet?
    private var subscriptions = Set<AnyCancellable>()
    private let source: SendSource

    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var walletsRepository: WalletsRepository
    @Injected private var tokensRepository: TokensRepository
    @Injected private var notificationService: NotificationService
    @Injected private var analyticsManager: AnalyticsManager

    private let sendHistoryService: SendHistoryService
    private let recipientSearchService: RecipientSearchService
    private var searchTask: Task<Void, Never>?
    
    @Published var loadingState: LoadableState = .notRequested
    @Published var isFirstResponder: Bool = false

    @Published var input: String = ""
    @Published var searchResult: RecipientSearchResult? = nil
    @Published var userWalletEnvironments: UserWalletEnvironments = .empty

    @Published var isSearching = false

    @Published var recipientsHistoryStatus: SendHistoryService.Status = .ready
    @Published var recipientsHistory: [Recipient] = []

    var autoSelectTheOnlyOneResultMode: AutoSelectTheOnlyOneResultMode?
    var fromQR: Bool = false

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
        preChosenWallet: Wallet?,
        source: SendSource
    ) {
        self.recipientSearchService = recipientSearchService
        self.preChosenWallet = preChosenWallet
        self.sendHistoryService = sendHistoryService
        self.source = source

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

        sendHistoryService.statusPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.recipientsHistoryStatus, on: self)
            .store(in: &subscriptions)

        sendHistoryService.recipientsPublisher
            .receive(on: RunLoop.main)
            .map { Array($0.prefix(10)) }
            .assign(to: \.recipientsHistory, on: self)
            .store(in: &subscriptions)

        $input
            .combineLatest($userWalletEnvironments)
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { [weak self] (query: String, _) in
                guard let self = self else { return }
                self.search(
                    query: query,
                    autoSelectTheOnlyOneResultMode: self.autoSelectTheOnlyOneResultMode,
                    fromQR: self.fromQR
                )
                self.autoSelectTheOnlyOneResultMode = nil
                self.fromQR = false
            }.store(in: &subscriptions)

        logOpen()
    }

    @MainActor
    func autoSelectTheOnlyOneResult(result: RecipientSearchResult, fromQR: Bool) {
        // Wait result and select first result
        switch result {
        case let .ok(recipients) where recipients.count == 1:
            guard
                let recipient: Recipient = recipients.first,
                recipient.attributes.contains(.funds)
            else { return }

            selectRecipient(recipient, fromQR: fromQR)

            if fromQR {
                notifyAddressRecognized(recipient: recipient)
            }
        default:
            break
        }
    }

    func searchQR(query: String, autoSelectTheOnlyOneResultMode: AutoSelectTheOnlyOneResultMode) {
        fromQR = true
        self.autoSelectTheOnlyOneResultMode = autoSelectTheOnlyOneResultMode
        input = query
    }

    private func search(query: String, autoSelectTheOnlyOneResultMode: AutoSelectTheOnlyOneResultMode?, fromQR: Bool) {
        searchTask?.cancel()
        let currentSearchTerm = query.trimmingCharacters(in: .whitespaces).lowercased()
        if currentSearchTerm.isEmpty {
            searchResult = nil
            isSearching = false
        } else {
            isSearching = true
            searchTask = Task { [weak self] in
                let result = await recipientSearchService.search(
                    input: currentSearchTerm,
                    env: userWalletEnvironments,
                    preChosenToken: preChosenWallet?.token
                )

                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.isSearching = false
                    self?.searchResult = result
                }
                if
                    let autoSelectTheOnlyOneResultMode = autoSelectTheOnlyOneResultMode,
                    autoSelectTheOnlyOneResultMode.isEnabled
                {
                    try? await Task.sleep(nanoseconds: autoSelectTheOnlyOneResultMode.delay!)
                    guard !Task.isCancelled else { return }
                    await autoSelectTheOnlyOneResult(result: result, fromQR: fromQR)
                }
            }
        }
    }

    @MainActor
    func past() {
        isFirstResponder = false
        guard let text = clipboardManager.stringFromClipboard() else { return }
        autoSelectTheOnlyOneResultMode = .enabled(delay: 0)
        input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        notificationService.showToast(title: "✅", text: L10n.pastedFromClipboard)
    }

    @MainActor
    func qr() {
        isFirstResponder = false
        coordinator.scanQRSubject.send(())
    }

    @MainActor
    func selectRecipient(_ recipient: Recipient, fromQR: Bool = false) {
        logRecipient(recipient: recipient, fromQR: fromQR)
        coordinator.selectRecipientSubject.send(recipient)
    }

    @MainActor
    func notifyAddressRecognized(recipient: Recipient) {
        let text = L10n.theAddressIsRecognized("\(recipient.address.prefix(6))...\(recipient.address.suffix(6))")
        notificationService.showToast(title: "✅", text: text)
    }

    @MainActor
    func load() async {
        loadingState = .loading
        do {
            try await Resolver.resolve(SwapServiceType.self).reload()
            loadingState = .loaded
        } catch {
            loadingState = .error(error.readableDescription)
        }
    }
}

// MARK: - Analytics

private extension RecipientSearchViewModel {
    enum RecipientInputType: String {
        case username, address, QR
    }

    func logOpen() {
        analyticsManager.log(event: AmplitudeEvent.sendnewRecipientScreen(source: source.rawValue))
    }

    func logRecipient(recipient: Recipient, fromQR: Bool) {
        let inputType: RecipientInputType
        if fromQR {
            inputType = .QR
        } else {
            switch recipient.category {
            case .username:
                inputType = .username
            default:
                inputType = .address
            }
        }
        analyticsManager
            .log(event: AmplitudeEvent.sendnewRecipientAdd(type: inputType.rawValue, source: source.rawValue))
    }
}
