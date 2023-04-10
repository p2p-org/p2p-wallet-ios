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
import FeeRelayerSwift

enum LoadableState: Equatable {
    case notRequested
    case loading
    case loaded
    case error(String?)

    var isError: Bool {
        switch self {
        case .error: return true
        default: return false
        }
    }
}

/// State for SendViaLink feature
struct SendViaLinkState: Equatable {
    /// Indicate if the feature itself is disabled or not (via FT)
    let isFeatureDisabled: Bool
    /// Default limit for a day
    let reachedLimit: Bool
    
    /// Indicate if user can create link
    var canCreateLink: Bool {
        !isFeatureDisabled && !reachedLimit
    }
}

@MainActor
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

    @Published var input = "" {
        didSet {
            sendViaLinkVisible = input.isEmpty
        }
    }
    @Published var searchResult: RecipientSearchResult? = nil
    @Published var userWalletEnvironments: UserWalletEnvironments = .empty

    @Published var isSearching = false

    @Published var recipientsHistoryStatus: SendHistoryService.Status = .ready
    @Published var recipientsHistory: [Recipient] = []
    
    @Published var sendViaLinkState = SendViaLinkState(
        isFeatureDisabled: true,
        reachedLimit: false
    )
    @Published var sendViaLinkVisible = true

    var autoSelectTheOnlyOneResultMode: AutoSelectTheOnlyOneResultMode?
    var fromQR: Bool = false

    struct Coordinator {
        fileprivate let selectRecipientSubject: PassthroughSubject<Recipient, Never> = .init()
        var selectRecipientPublisher: AnyPublisher<Recipient, Never> { selectRecipientSubject.eraseToAnyPublisher() }

        fileprivate let scanQRSubject: PassthroughSubject<Void, Never> = .init()
        var scanQRPublisher: AnyPublisher<Void, Never> { scanQRSubject.eraseToAnyPublisher() }
        
        fileprivate let sendViaLinkSubject: PassthroughSubject<Void, Never> = .init()
        var sendViaLinkPublisher: AnyPublisher<Void, Never> { sendViaLinkSubject.eraseToAnyPublisher() }
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
            .assignWeak(to: \.recipientsHistoryStatus, on: self)
            .store(in: &subscriptions)

        sendHistoryService.recipientsPublisher
            .receive(on: RunLoop.main)
            .map { Array($0.prefix(10)) }
            .assignWeak(to: \.recipientsHistory, on: self)
            .store(in: &subscriptions)

        $input
            .removeDuplicates()
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
        input.removeAll() // need to trigger publisher update in case of the same input
        input = query
    }

    private func search(query: String, autoSelectTheOnlyOneResultMode: AutoSelectTheOnlyOneResultMode?, fromQR: Bool) {
        searchTask?.cancel()
        let currentSearchTerm = query.trimmingCharacters(in: .whitespaces)
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
                    autoSelectTheOnlyOneResult(result: result, fromQR: fromQR)
                }
            }
        }
    }

    func past() {
        guard let text = clipboardManager.stringFromClipboard(), !text.isEmpty else { return }
        isFirstResponder = false
        autoSelectTheOnlyOneResultMode = .enabled(delay: 0)
        input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        notificationService.showToast(title: "✅", text: L10n.pastedFromClipboard)
    }

    func qr() {
        isFirstResponder = false
        coordinator.scanQRSubject.send(())
    }

    func selectRecipient(_ recipient: Recipient, fromQR: Bool = false) {
        logRecipient(recipient: recipient, fromQR: fromQR)
        coordinator.selectRecipientSubject.send(recipient)
    }

    func notifyAddressRecognized(recipient: Recipient) {
        let text = L10n.theAddressIsRecognized("\(recipient.address.prefix(6))...\(recipient.address.suffix(6))")
        notificationService.showToast(title: "✅", text: text, haptic: false)
    }

    func load() async {
        loadingState = .loading
        do {
            let _ = try await(
                Resolver.resolve(SwapServiceType.self).reload(),
                checkIfSendViaLinkAvailable()
            )
            loadingState = .loaded
            isFirstResponder = true
        } catch {
            loadingState = .error(error.readableDescription)
        }
    }
    
    // MARK: - Send via link
    
    func checkIfSendViaLinkAvailable() async throws {
        if available(.sendViaLinkEnabled) {
            // get relay context
            let usageStatus = try await Resolver.resolve(RelayContextManager.self)
                .getCurrentContextOrUpdate()
                .usageStatus
            
            sendViaLinkState = SendViaLinkState(
                isFeatureDisabled: false,
                reachedLimit: usageStatus.reachedLimitLinkCreation
            )
        } else {
            sendViaLinkState = SendViaLinkState(
                isFeatureDisabled: true,
                reachedLimit: false
            )
        }
    }
    
    func sendViaLink() {
        analyticsManager.log(event: .sendClickStartCreateLink)
        coordinator.sendViaLinkSubject.send(())
    }
    
    #if !RELEASE
    func sendToTotallyNewAccount() {
        let keypair = try! KeyPair()
        selectRecipient(
            .init(
                address: keypair.publicKey.base58EncodedString,
                category: .solanaAddress,
                attributes: [.funds]
            )
        )
    }
    #endif
}

// MARK: - Analytics

private extension RecipientSearchViewModel {
    enum RecipientInputType: String {
        case username, address, QR
    }

    func logOpen() {
        analyticsManager.log(event: .sendnewRecipientScreen(source: source.rawValue))
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
            .log(event: .sendnewRecipientAdd(type: inputType.rawValue, source: source.rawValue))
    }
}
