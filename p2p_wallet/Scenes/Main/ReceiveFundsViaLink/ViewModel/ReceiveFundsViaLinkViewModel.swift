//
//  ReceiveFundsViaLinkViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 23.03.2023.
//

import AnalyticsManager
import Combine
import Foundation
import SolanaSwift
import Send
import Resolver
import FeeRelayerSwift

final class ReceiveFundsViaLinkViewModel: BaseViewModel, ObservableObject {
    // MARK: - Nested type

    enum FakeTransactionErrorType: String, CaseIterable, Identifiable {
        case noError
        case networkError
        case otherError
        var id: Self { self }
    }
    
    // Dependencies
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var sendViaLinkDataService: SendViaLinkDataService
    @Injected private var tokensRepository: SolanaTokensRepository
    @Injected private var walletsRepository: WalletsRepository
    
    // Subjects
    private let closeSubject = PassthroughSubject<Void, Never>()
    private let sizeChangedSubject = PassthroughSubject<CGFloat, Never>()
    private let linkErrorSubject = PassthroughSubject<LinkErrorView.Model, Never>()
    
    // Properties
    private let url: URL
    private var claimableToken: ClaimableTokenInfo?
    private var token: Token?
    
    // MARK: - To Coordinator
    
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }
    var sizeChanged: AnyPublisher<CGFloat, Never> { sizeChangedSubject.eraseToAnyPublisher() }
    var linkError: AnyPublisher<LinkErrorView.Model, Never> { linkErrorSubject.eraseToAnyPublisher() }
    
    // MARK: - To View
    
    @Published var state: State = .pending
    @Published var processingState: TransactionProcessView.Status = .loading(message: "")
    @Published var processingVisible = false
    @Published var isReloading = false
    
    // Debugging
    #if !RELEASE
    @Published var isFakeSendingTransaction: Bool = false {
        didSet {
            if isFakeSendingTransaction {
                fakeTransactionErrorType = .noError
            }
        }
    }
    @Published var fakeTransactionErrorType: FakeTransactionErrorType = .noError
    #endif
    
    // MARK: - Init
    
    init(url: URL) {
        self.url = url
        super.init()
        loadTokenInfo()
    }
    
    // MARK: - From View
    
    func onAppear() {
        analyticsManager.log(event: .claimStartScreenOpen)
    }
    
    func closeClicked() {
        analyticsManager.log(event: .claimClickClose)
        closeSubject.send()
    }
    
    func confirmClicked() {
        // Get needed params
        guard
            let claimableToken = claimableToken,
            let token = token,
            let pubkeyStr = walletsRepository.nativeWallet?.pubkey,
            let pubkey = try? PublicKey(string: pubkeyStr)
        else { return }

        let cryptoAmount = claimableToken.lamports
            .convertToBalance(decimals: claimableToken.decimals)

analyticsManager.log(event: .claimClickConfirmed(
            pubkey: pubkeyStr,
            tokenName: token.symbol,
            tokenValue: cryptoAmount,
            fromAddress: claimableToken.account
        ))
        
        #if !RELEASE
        let isFakeSendingTransaction = isFakeSendingTransaction
        let fakeTransactionErrorType = fakeTransactionErrorType
        #else
        let isFakeSendingTransaction = false
        let fakeTransactionErrorType = nil
        #endif

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
                receiver: pubkey,
                isFakeTransaction: isFakeSendingTransaction,
                fakeTransactionErrorType: fakeTransactionErrorType
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
                    self.analyticsManager.log(event: .claimErrorDefaultReject)
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
    
    func gotItClicked() {
        analyticsManager.log(event: .claimClickEnd)
        closeSubject.send()
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
                    showLinkWasClaimedError()
                    return
                }

                let cryptoAmountStr = cryptoAmount.tokenAmountFormattedString(symbol: token.symbol)
                let model = Model(token: token, cryptoAmount: cryptoAmountStr)
                
                self.claimableToken = claimableToken
                self.token = token
                await MainActor.run {
                    state = .loaded(model: model)
                    isReloading = false
                    sizeChangedSubject.send(422)
                }
            } catch {
                await MainActor.run {
                    guard let error = error as? SendViaLinkDataServiceError else {
                        showFailedToGetDataError()
                        return
                    }
                    switch error {
                    case .claimableAssetNotFound:
                        showLinkWasClaimedError()
                    case .invalidSeed, .invalidURL:
                        showFullLinkError(
                            title: L10n.thisLinkIsBroken,
                            subtitle: L10n.youCanTReceiveFundsWithIt,
                            image: .womanNotFound
                        )
                    case .lastTransactionNotFound:
                        showFailedToGetDataError()
                    }
                }
            }
        }
    }
    
    private func showFullLinkError(title: String, subtitle: String, image: UIImage) {
        linkErrorSubject.send(LinkErrorView.Model(title: title, subtitle: subtitle, image: image))
    }
    
    private func showFailedToGetDataError() {
        state = .failure
        sizeChangedSubject.send(594)
        isReloading = false
    }
    
    private func showLinkWasClaimedError() {
        showFullLinkError(
            title: L10n.thisOneTimeLinkIsAlreadyClaimed,
            subtitle: L10n.youCanTReceiveFundsWithIt,
            image: .sendViaLinkClaimed
        )
    }
}

// MARK: - Independent helpers

func claimSendViaLinkExecution(
    claimableToken: ClaimableTokenInfo,
    receiver: PublicKey,
    isFakeTransaction: Bool,
    fakeTransactionErrorType: ReceiveFundsViaLinkViewModel.FakeTransactionErrorType
) async throws -> TransactionID {
    // fake transaction for debugging
    if isFakeTransaction {
        // fake delay api call 1s
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // simulate error if needed
        switch fakeTransactionErrorType {
        case .noError:
            break
        case .otherError:
            throw SolanaError.unknown
        case .networkError:
            throw NSError(domain: "Network error", code: NSURLErrorNetworkConnectionLost)
        }
        
        return .fakeTransactionSignature(id: UUID().uuidString)
    }
    
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
