//
//  ReceiveFundsViaLinkViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 23.03.2023.
//

import Combine
import Foundation
import SolanaSwift
import Send
import Resolver

final class ReceiveFundsViaLinkViewModel: ObservableObject {
    
    // Dependencies
    @Injected private var sendViaLinkDataService: SendViaLinkDataService
    @Injected private var tokensRepository: SolanaTokensRepository
    @Injected private var walletsRepository: WalletsRepository
    
    // Subjects
    private let closeSubject = PassthroughSubject<Void, Never>()
    private let sizeChangedSubject = PassthroughSubject<Void, Never>()
    private let linkWasClaimedSubject = PassthroughSubject<Void, Never>()
    
    // Properties
    private let url: URL
    private var claimableToken: ClaimableTokenInfo?
    private var token: Token?
    
    // MARK: - To Coordinator
    
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }
    var sizeChanged: AnyPublisher<Void, Never> { sizeChangedSubject.eraseToAnyPublisher() }
    var linkWasClaimed: AnyPublisher<Void, Never> { linkWasClaimedSubject.eraseToAnyPublisher() }
    
    // MARK: - To View
    
    @Published var state: State = .pending
    @Published var processingState: TransactionProcessView.Status = .loading(message: "")
    @Published var processingVisible = false
    @Published var isReloading = false
    
    // MARK: - Init
    
    init(url: URL) {
        self.url = url
        loadTokenInfo()
    }
    
    // MARK: - From View
    
    func closeClicked() {
        closeSubject.send()
    }
    
    func confirmClicked() {
        guard
            let claimableToken = claimableToken,
            let token = token,
            let pubkey = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey)
        else { return }

        processingState = .loading(message: L10n.itUsuallyTakes520SecondsForATransactionToComplete)
        processingVisible = true
        sizeChangedSubject.send()
        
        Task {
            do {
                _ = try await self.sendViaLinkDataService.claim(
                    token: claimableToken,
                    receiver: pubkey,
                    feePayer: pubkey
                )
                let cryptoAmount = claimableToken.lamports
                    .convertToBalance(decimals: claimableToken.decimals)
                    .tokenAmountFormattedString(symbol: token.symbol)

                await MainActor.run { [weak self] in
                    self?.state = .confirmed(cryptoAmount: cryptoAmount)
                    self?.processingVisible = false
                    self?.sizeChangedSubject.send()
                }
            } catch {
                await MainActor.run { [weak self] in
                    if (error as NSError).isNetworkConnectionError {
                        self?.processingState = .error(message: NSAttributedString(
                            string: L10n.TheTransactionWasRejectedAfterFailedInternetConnection.openYourLinkAgain
                        ))
                    } else {
                        self?.processingState = .error(message: NSAttributedString(
                            string: L10n.theTransactionWasRejectedByTheSolanaBlockchain
                        ))
                    }
                }
            }
        }
    }
    
    func reloadClicked() {
        guard !isReloading else { return }
        isReloading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.loadTokenInfo()
        }
    }
    
    func statusErrorClicked() {
        guard let claimableToken = claimableToken else { return }
        let cryptoAmount = claimableToken.lamports.convertToBalance(decimals: claimableToken.decimals)
        
        if cryptoAmount == 0 {
            linkWasClaimedSubject.send()
        }
    }
    
    // MARK: - Private
    
    private func loadTokenInfo() {
        Task {
            do {
                let claimableToken = try await self.sendViaLinkDataService.getClaimableTokenInfo(url: self.url)
                let token = try await self.tokensRepository.getTokensList(useCache: true)
                    .first { $0.address == claimableToken.mintAddress }

                guard let token = token else { return }

                let cryptoAmount = claimableToken.lamports
                    .convertToBalance(decimals: claimableToken.decimals)
                    .tokenAmountFormattedString(symbol: token.symbol)
                let model = Model(
                    date: Date().string(withFormat: "MMMM dd, yyyy @ HH:mm"), // TODO: - Add date after adding to sendViaLinkDataService
                    token: token,
                    cryptoAmount: cryptoAmount
                )
                self.claimableToken = claimableToken
                self.token = token
                await MainActor.run { [weak self] in
                    self?.state = .loaded(model: model)
                    self?.isReloading = false
                    self?.sizeChangedSubject.send()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .failure
                    self?.isReloading = false
                    self?.sizeChangedSubject.send()
                }
            }
        }
    }
}

// MARK: - State

extension ReceiveFundsViaLinkViewModel {
    enum State {
        case pending
        case loaded(model: Model)
        case confirmed(cryptoAmount: String)
        case failure
    }
    
    struct Model {
        let date: String
        let token: Token
        let cryptoAmount: String
    }
}
