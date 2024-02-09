import AnalyticsManager
import Combine
import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send
import SolanaSwift
import TokenService
import UIKit

final class ReceiveFundsViaLinkViewModel: BaseViewModel, ObservableObject {
    // Dependencies
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var sendViaLinkDataService: SendViaLinkDataService
    @Injected private var tokensRepository: SolanaTokensService

    // Subjects
    private let closeSubject = PassthroughSubject<Void, Never>()
    private let sizeChangedSubject = PassthroughSubject<CGFloat, Never>()
    private let linkErrorSubject = PassthroughSubject<LinkErrorView.Model, Never>()

    // Properties
    private let url: URL
    private var claimableToken: ClaimableTokenInfo?
    private var token: TokenMetadata?

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

    func closeClicked() {
        closeSubject.send()
    }

    func confirmClicked() {
        // Get needed params
        guard let claimableToken = claimableToken, let token = token else { return }

        let cryptoAmount = claimableToken.lamports
            .convertToBalance(decimals: claimableToken.decimals)

        analyticsManager.log(event: .claimClickConfirmed(
            pubkey: claimableToken.keypair.publicKey.base58EncodedString,
            tokenName: token.symbol,
            tokenValue: cryptoAmount
        ))

        #if !RELEASE
            let isFakeSendingTransaction = isFakeSendingTransaction
            let fakeTransactionErrorType = fakeTransactionErrorType
        #else
            let isFakeSendingTransaction = false
            let fakeTransactionErrorType = FakeTransactionErrorType.noError
        #endif

        // Notify loading
        sizeChangedSubject.send(522)
        processingState = .loading(message: L10n.theTransactionWillBeCompletedInAFewSeconds)
        processingVisible = true

        // Form raw transaction
        let transaction = ClaimSentViaLinkTransaction(
            claimableTokenInfo: claimableToken,
            token: token,
            destinationWallet: .classicSPLTokenAccount(
                address: claimableToken.account,
                lamports: 0,
                token: token
            ),
            tokenAmount: cryptoAmount,
            isFakeTransaction: isFakeSendingTransaction,
            fakeTransactionErrorType: fakeTransactionErrorType,
            feePayer: claimableToken.keypair
        )

        // Send it to transactionHandler
        let transactionHandler = Resolver.resolve(TransactionHandlerType.self)
        let transactionIndex = transactionHandler.sendTransaction(transaction)

        // Observe transaction and update status
        transactionHandler.observeTransaction(transactionIndex: transactionIndex)
            .compactMap { $0 }
//            .filter { $0.isConfirmedOrError } // numberOfConfirmation is greater than 0
            .filter {
                $0.status
                    .isSent // numberOfConfirmation is greater than OR EQUAL 0, increase the speed by returning success
                // status right after it is sent
            }
            .prefix(1)
            .receive(on: RunLoop.main)
            .sink { [weak self] tx in
                guard let self else { return }
                if let error = tx.status.error {
                    self.analyticsManager.log(event: .claimErrorDefaultReject)
                    if error.isNetworkConnectionError {
                        self.processingState = .error(message: NSAttributedString(
                            string: L10n.TheTransactionWasRejectedAfterFailedInternetConnection.openYourLinkAgain
                        ))
                    } else {
                        self.processingState = .error(message: NSAttributedString(
                            string: L10n.TheTransactionWasRejected.openYourLinkAgain
                        ))
                    }
                } else {
                    self.state = .confirmed(
                        cryptoAmount: cryptoAmount
                            .tokenAmountFormattedString(symbol: token.symbol)
                    )
                    self.processingVisible = false
                    self.sizeChangedSubject.send(662)
                    self.analyticsManager.log(event: .claimEndScreenOpen)
                }
            }
            .store(in: &subscriptions)
    }

    func reloadClicked() {
        guard !isReloading else { return }
        isReloading = true
        loadTokenInfo()
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

                // Native solana token
                let token: TokenMetadata
                if claimableToken.mintAddress == PublicKey.wrappedSOLMint.base58EncodedString {
                    token = .nativeSolana
                }

                // Other spl tokens
                else {
                    token = try await self.tokensRepository.get(
                        address: claimableToken.mintAddress
                    ) ??
                        .unsupported(
                            tags: nil,
                            mint: claimableToken.mintAddress,
                            decimals: claimableToken.decimals,
                            symbol: "",
                            supply: nil
                        )
                }

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
                self.analyticsManager.log(event: .claimStartScreenOpen)
                await MainActor.run {
                    state = .loaded(model: model)
                    isReloading = false
                    sizeChangedSubject.send(422)
                }
            } catch {
                await MainActor.run {
                    guard let error = error as? SendViaLinkDataServiceError else {
                        showError(error)
                        return
                    }
                    switch error {
                    case .claimableAssetNotFound:
                        showLinkWasClaimedError()
                    case .invalidSeed, .invalidURL:
                        showFullLinkError(
                            title: L10n.thisLinkIsBroken,
                            subtitle: L10n.youCanTReceiveMoneyWithIt,
                            image: .womanNotFound
                        )
                    case .lastTransactionNotFound:
                        showError(error)
                    }
                }
            }
        }
    }

    private func showFullLinkError(title: String, subtitle: String, image: ImageResource) {
        linkErrorSubject.send(LinkErrorView.Model(title: title, subtitle: subtitle, image: image))
    }

    private func showError(_ error: Error) {
        if error.isNetworkConnectionError {
            showConnectionError()
        } else {
            state = .failure(
                title: L10n.failedToGetData,
                subtitle: nil,
                image: .sendViaLinkClaimError
            )
            sizeChangedSubject.send(594)
        }
        isReloading = false
    }

    private func showConnectionError() {
        state = .failure(
            title: L10n.youHaveNoInternetConnection,
            subtitle: nil,
            image: .connectionErrorCat
        )
        sizeChangedSubject.send(534)
    }

    private func showLinkWasClaimedError() {
        analyticsManager.log(event: .claimErrorAlreadyClaimed)
        showFullLinkError(
            title: L10n.theLinkIsAlreadyClaimed,
            subtitle: L10n.youCanTReceiveMoneyWithIt,
            image: .sendViaLinkClaimed
        )
    }
}

// MARK: - State

extension ReceiveFundsViaLinkViewModel {
    enum State {
        case pending
        case loaded(model: Model)
        case confirmed(cryptoAmount: String)
        case failure(title: String, subtitle: String?, image: ImageResource)
    }

    struct Model {
        let token: TokenMetadata
        let cryptoAmount: String
    }
}
