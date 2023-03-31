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
import FeeRelayerSwift

final class ReceiveFundsViaLinkViewModel: BaseViewModel, ObservableObject {
    
    // Dependencies
    @Injected private var sendViaLinkDataService: SendViaLinkDataService
    @Injected private var tokensRepository: SolanaTokensRepository
    @Injected private var walletsRepository: WalletsRepository
    
    // Subjects
    private let closeSubject = PassthroughSubject<Void, Never>()
    private let sizeChangedSubject = PassthroughSubject<CGFloat, Never>()
    private let linkWasClaimedSubject = PassthroughSubject<Void, Never>()
    
    // Properties
    private let url: URL
    private var claimableToken: ClaimableTokenInfo?
    private var token: Token?
    
    // MARK: - To Coordinator
    
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }
    var sizeChanged: AnyPublisher<CGFloat, Never> { sizeChangedSubject.eraseToAnyPublisher() }
    var linkWasClaimed: AnyPublisher<Void, Never> { linkWasClaimedSubject.eraseToAnyPublisher() }
    
    // MARK: - To View
    
    @Published var state: State = .pending
    @Published var processingState: TransactionProcessView.Status = .loading(message: "")
    @Published var processingVisible = false
    @Published var isReloading = false
    
    // MARK: - Init
    
    init(url: URL) {
        self.url = url
        super.init()
        loadTokenInfo()
    }
    
    // MARK: - From View
    
    func closeClicked() {
        closeSubject.send()
    }
    
    func confirmClicked() {
        // Get needed params
        guard
            let claimableToken = claimableToken,
            let token = token,
            let pubkey = try? PublicKey(string: walletsRepository.nativeWallet?.pubkey)
        else { return }

        let cryptoAmount = claimableToken.lamports
            .convertToBalance(decimals: claimableToken.decimals)

        // Notify loading
        sizeChangedSubject.send(522)
        processingState = .loading(message: L10n.itUsuallyTakes520SecondsForATransactionToComplete)
        processingVisible = true
        
        // Form raw transaction
        let transaction = ClaimSentViaLinkTransaction(
            claimableTokenInfo: claimableToken,
            token: token,
            destinationWallet: Wallet(pubkey: claimableToken.account, token: token),
            tokenAmount: cryptoAmount
        ) {
            try await claimSendViaLinkExecution(
                claimableToken: claimableToken,
                receiver: pubkey
            )
        }

        // Send it to transactionHandler
        let transactionHandler = Resolver.resolve(TransactionHandlerType.self)
        let transactionIndex = transactionHandler.sendTransaction(transaction)

        // Observe transaction and update status
        transactionHandler.observeTransaction(transactionIndex: transactionIndex)
            .compactMap {$0}
            .filter {
                $0.status.error != nil || $0.status.isFinalized || ($0.status.numberOfConfirmations ?? 0) > 0
            }
            .prefix(1)
            .receive(on: RunLoop.main)
            .sink { [weak self] tx in
                guard let self else { return }
                if let error = tx.status.error {
                    if (error as NSError).isNetworkConnectionError {
                        self.processingState = .error(message: NSAttributedString(
                            string: L10n.TheTransactionWasRejectedAfterFailedInternetConnection.openYourLinkAgain
                        ))
                    } else {
                        self.processingState = .error(message: NSAttributedString(
                            string: L10n.theTransactionWasRejectedByTheSolanaBlockchain
                        ))
                    }
                } else {
                    self.state = .confirmed(
                        cryptoAmount: cryptoAmount
                            .tokenAmountFormattedString(symbol: token.symbol)
                    )
                    self.processingVisible = false
                    self.sizeChangedSubject.send(566)
                }
            }
            .store(in: &subscriptions)
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

                if cryptoAmount == 0 {
                    await MainActor.run { [weak self] in
                        self?.linkWasClaimedSubject.send()
                    }
                    return
                }

                let cryptoAmountStr = cryptoAmount.tokenAmountFormattedString(symbol: token.symbol)
                let model = Model(token: .nativeSolana, cryptoAmount: "cryptoAmountStr")
                
                self.claimableToken = claimableToken
                self.token = token
                await MainActor.run { [weak self] in
                    self?.state = .loaded(model: model)
                    self?.isReloading = false
                    self?.sizeChangedSubject.send(422)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .failure
                    self?.sizeChangedSubject.send(594)
                    self?.isReloading = false
                }
            }
        }
    }
}

// MARK: - Independent helpers

func claimSendViaLinkExecution(
    claimableToken: ClaimableTokenInfo,
    receiver: PublicKey
) async throws -> TransactionID {
    // get services
    let sendViaLinkDataService = Resolver.resolve(SendViaLinkDataService.self)
    let contextManager = Resolver.resolve(RelayContextManager.self)
    let solanaAPIClient = Resolver.resolve(SolanaAPIClient.self)
    
    let context = try await contextManager
        .getCurrentContextOrUpdate()
    
    // prepare transaction, get recent blockchash
    var (preparedTransaction, recentBlockhash) = try await(
        sendViaLinkDataService.claim(
            token: claimableToken,
            receiver: receiver,
            feePayer: context.feePayerAddress
        ),
        solanaAPIClient.getRecentBlockhash()
    )
    
    preparedTransaction.transaction.recentBlockhash = recentBlockhash
    
    // get feePayer's signature
    let feePayerSignature = try await Resolver.resolve(RelayService.self)
        .signRelayTransaction(
            preparedTransaction,
            config: FeeRelayerConfiguration(
                operationType: .sendViaLink, // TODO: - Received via link?
                currency: claimableToken.mintAddress,
                autoPayback: false
            )
        )
    
    // sign transaction by user
    try preparedTransaction.transaction.sign(signers: [claimableToken.keypair])
    
    // add feePayer's signature
    try preparedTransaction.transaction.addSignature(
        .init(
            signature: Data(Base58.decode(feePayerSignature)),
            publicKey: context.feePayerAddress
        )
    )
    
    // serialize transaction
    let serializedTransaction = try preparedTransaction.transaction.serialize().base64EncodedString()
    
    // send to solanaBlockchain
    return try await solanaAPIClient.sendTransaction(transaction: serializedTransaction, configs: RequestConfiguration(encoding: "base64")!)
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
        let token: Token
        let cryptoAmount: String
    }
}
