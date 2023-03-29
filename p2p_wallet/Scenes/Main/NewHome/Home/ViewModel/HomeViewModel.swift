//
//  HomeViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Dependencies
    
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService
    @Injected private var accountStorage: AccountStorageType
    @Injected private var nameStorage: NameStorageType
    @Injected private var createNameService: CreateNameService
    @Injected private var walletsRepository: WalletsRepository

    // MARK: - Published properties

    @Published var state = State.pending
    @Published var address = ""

    // MARK: - Properties

    private var subscriptions = Set<AnyCancellable>()
    private var isInitialized = false

    // MARK: - Initializers

    init() {
        // bind
        bind()
        
        // reload
        reload()
    }

    // MARK: - Methods
    
    func reload() {
        walletsRepository.reload()
    }

    func copyToClipboard() {
        // get name and pubkey
        let name = nameStorage.getName()
        let hasName = name != nil
        let pubkey = walletsRepository.nativeWallet?.pubkey
        
        // copy to clipboard
        clipboardManager.copyToClipboard(name ?? pubkey ?? "")
        
        // notify user
        notificationsService.showToast(title: "🖤", text: hasName ? L10n.nameCopiedToClipboard: L10n.addressWasCopiedToClipboard, haptic: true)
        
        // log
        analyticsManager.log(event: .mainCopyAddress)
    }

    func updateAddressIfNeeded() {
        if let name = nameStorage.getName(), !name.isEmpty {
            address = "\(name).key"
        } else if let address = accountStorage.account?.publicKey.base58EncodedString.shortAddress {
            self.address = address
        }
    }
}

private extension HomeViewModel {
    func bind() {
        // isInitialized
        walletsRepository.statePublisher
            .filter { $0 == .loaded }
            .prefix(1)
            .map { _ in true}
            .assign(to: \.isInitialized, on: self)
            .store(in: &subscriptions)

        // state, address, error, log
        Publishers.CombineLatest(
            walletsRepository.statePublisher.removeDuplicates(),
            walletsRepository.dataPublisher.removeDuplicates()
        )
            .sink { [weak self] state, data in
                print("state, data.count: ", state, data.count)
                
                guard let self else { return }
                
                // accumulate total amount
                let fiatAmount = data.totalAmountInCurrentFiat
                let isEmpty = fiatAmount <= 0
                
                // address
                self.updateAddressIfNeeded()
                
                // state
                switch state {
                case .initializing,
                     .loading where !self.isInitialized:
                    self.state = .pending
                default:
                    self.state = isEmpty ? .empty: .withTokens
                    
                    // log
                    self.analyticsManager.log(parameter: .userHasPositiveBalance(!isEmpty))
                    self.analyticsManager.log(parameter: .userAggregateBalance(fiatAmount))
                }
            }
            .store(in: &subscriptions)
        
        // update name when needed
        createNameService.createNameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSuccess in
                guard isSuccess else { return }
                self?.updateAddressIfNeeded()
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Nested types

extension HomeViewModel {
    enum State {
        case pending
        case withTokens
        case empty
    }
}

// MARK: - Helpers

private extension String {
    var shortAddress: String {
        "\(prefix(4))...\(suffix(4))"
    }
}
