import Send
import SkeletonUI
import SwiftUI

struct RecipientSearchView: View {
    @ObservedObject var viewModel: RecipientSearchViewModel
    @SwiftUI.Environment(\.scenePhase) var scenePhase

    var body: some View {
        switch viewModel.loadingState {
        case .notRequested:
            Text("")
        case .loading:
            ProgressView()
        case .loaded:
            loadedView
        case .error:
            ErrorView {
                Task { await viewModel.load() }
            }
        }
    }

    var loadedView: some View {
        ZStack {
            Color(.smoke)
                .onTapGesture { viewModel.isFirstResponder = false }
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Search field
                RecipientSearchField(
                    text: $viewModel.input,
                    isLoading: .constant(false),
                    isFirstResponder: $viewModel.isFirstResponder
                ) {
                    viewModel.past()
                } scan: {
                    viewModel.qr()
                }
                .accessibilityIdentifier("RecipientSearchView.loadedView.RecipientSearchField")
                
                // Send via link
                if !viewModel.sendViaLinkState.isFeatureDisabled, viewModel.sendViaLinkVisible {
                    sendViaLinkView
                }
                
                #if !RELEASE
                // Send to totally new account (for debugging)
                Button {
                    viewModel.sendToTotallyNewAccount()
                } label: {
                    Text("Tap to send to totally new account (asset will be lost)")
                        .apply(style: .label2)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                #endif

                // Result
                if viewModel.isSearching {
                    skeleton
                        .padding(.top, 32)
                        .accessibilityIdentifier("RecipientSearchView.loadedView.Skeleton")
                    Spacer()
                } else {
                    if let result = viewModel.searchResult {
                        VStack {
                            switch result {
                            case let .ok(recipients):
                                // Ok case
                                if recipients.isEmpty {
                                    // Not found
                                    NotFoundView(text: L10n.AddressNotFound.tryAnotherOne)
                                        .accessibilityIdentifier("RecipientSearchView.loadedView.SendNotFoundView")
                                        .padding(.top, 32)
                                } else {
                                    // With result
                                    okView(recipients)
                                }
                            case let .missingUserToken(recipient):
                                // Missing user token
                                disabledAndReason(
                                    recipient,
                                    reason: L10n.youCannotSendFundsToThisAddressBecauseItBelongsToAnotherToken
                                )
                            case let .insufficientUserFunds(recipient):
                                // Insufficient funds
                                disabledAndReason(
                                    recipient,
                                    reason: L10n.accountCreationForThisAddressIsNotPossibleDueToInsufficientFunds
                                )
                            case let .selfSendingError(recipient):
                                switch recipient.category {
                                case let .solanaTokenAddress(_, token):
                                    disabledAndReason(
                                        recipient,
                                        reason: L10n.youCannotSendTokensToYourself,
                                        subtitle: L10n.yourAddress(token.symbol)
                                    )
                                default:
                                    disabledAndReason(
                                        recipient,
                                        reason: L10n.youCannotSendTokensToYourself,
                                        subtitle: L10n.yourAddress("").replacingOccurrences(of: "  ", with: " ") // Empty param creates 2 spaces
                                    )
                                }
                            case .nameServiceError:
                                tryLater(title: L10n.solanaNameServiceDoesnTRespond)
                                    .padding(.top, 38)
                                    .padding(.horizontal, 12)
                            case .solanaServiceError:
                                tryLater(title: "Solana Service doesn't respond")
                                    .padding(.top, 38)
                                    .padding(.horizontal, 12)
                            }
                            Spacer()
                        }
                    } else {
                        // History
                        history(viewModel.recipientsHistory)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .toolbar {
                // Navigation title
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(L10n.chooseARecipient)
                        Text("Solana network")
                            .apply(style: .label1)
                    }
                }
            }
        }
    }
    
    // MARK: - View Builder
    private var sendViaLinkView: some View {
        Button {
            viewModel.sendViaLink()
        } label: {
            VStack {
                RecipientCell(
                    image: Image(viewModel.sendViaLinkState.canCreateLink ? .sendViaLinkCircle: .sendViaLinkCircleDisabled)
                        .castToAnyView(),
                    title: L10n.sendMoneyViaLink,
                    subtitle: viewModel.sendViaLinkState.canCreateLink ? L10n.withoutAccountDetails: L10n.YouHaveReachedTheDailyLimitOfSendingFreeLinks.tryTomorrow,
                    multilinesForSubtitle: true
                )
            }
            
        }
        .disabled(!viewModel.sendViaLinkState.canCreateLink)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.white)
                .cornerRadius(radius: 16, corners: .allCorners)
        )
        .padding(.top, 16)
    }

    private var skeleton: some View {
        HStack(spacing: 12) {
            Circle()
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .skeleton(
                    with: viewModel.isSearching,
                    size: CGSize(width: 48, height: 48),
                    animated: .default
                )
                .padding(.leading, 16)
            VStack(alignment: .leading, spacing: 6) {
                Text("")
                    .fontWeight(.semibold)
                    .apply(style: .text2)
                    .skeleton(
                        with: viewModel.isSearching,
                        size: CGSize(width: 120, height: 12),
                        animated: .default
                    )
                Text("")
                    .apply(style: .label1)
                    .skeleton(
                        with: viewModel.isSearching,
                        size: CGSize(width: 120, height: 12),
                        animated: .default
                    )
            }
            Spacer()
        }
        .frame(height: 88)
        .frame(maxWidth: .infinity)
        .background(Color(.snow))
        .cornerRadius(16)
    }

    private func tryLater(title: String) -> some View {
        VStack(alignment: .center, spacing: 28) {
            Image(.warning)
                .foregroundColor(Color(.rose))
            Text(title)
                .apply(style: .text3)
                .accessibilityIdentifier("RecipientSearchView.tryLater.title")
            Text(L10n.weSuggestYouTryAgainLaterBecauseWeWillNotBeAbleToVerifyTheAddressIfYouContinue)
                .apply(style: .text3)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("RecipientSearchView.tryLater.weSuggestYouTryAgainLaterBecauseWeWillNotBeAbleToVerifyTheAddressIfYouContinue")
        }
        .foregroundColor(Color(.night))
    }

    private func disabledAndReason(_ recipient: Recipient, reason: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                Text(L10n.hereSWhatWeFound)
                    .apply(style: .text4)
                    .foregroundColor(Color(.mountain))
                Spacer()
            }

            RecipientCell(recipient: recipient, subtitle: subtitle)
                .disabled(true)
//                .accessibilityIdentifier("RecipientSearchView.disabledAndReason.RecipientCell")

            Text(reason)
                .apply(style: .text4)
                .foregroundColor(Color(.rose))
                .accessibilityIdentifier("RecipientSearchView.disabledAndReason.reason")
        }
    }

    private func history(_ recipients: [Recipient]) -> some View {
        Group {
            if recipients.isEmpty {
                emptyRecipientsView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(L10n.recentlyUsed)
                                .apply(style: .text4)
                                .foregroundColor(Color(.mountain))
                            Spacer()
                        }

                        VStack(spacing: 24) {
                            ForEach(recipients) { recipient in
                                VStack(spacing: 12) {
                                    Button {
                                        viewModel.selectRecipient(recipient)
                                    } label: {
                                        HStack {
                                            RecipientCell(recipient: recipient)
                                            Spacer()
                                        }
                                    }
                                    .accessibilityIdentifier("RecipientSearchView.loadedView.\(recipient.address)")
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .background(
                            Color(.white)
                                .cornerRadius(radius: 16, corners: .allCorners)
                        )
                    }.padding(.bottom, 8)
                }.onAppear {
                    UIScrollView.appearance().keyboardDismissMode = .interactive
                }
            }
        }
    }

    private var emptyRecipientsView: some View {
        VStack(spacing: 16) {
            switch viewModel.recipientsHistoryStatus {
            case .initializing:
                Spinner()
                    .frame(width: 28, height: 28)
                Text("Initializing transfer history")
                    .apply(style: .text3)
                Spacer()
            default:
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text(L10n.makeYourFirstTransaction)
                            .fontWeight(.bold)
                            .apply(style: .title2)
                        Text(L10n.toContinuePasteOrScanTheAddressOrTypeAUsername)
                            .apply(style: .text1)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        TextButtonView(
                            title: L10n.scanQR,
                            style: .primary,
                            size: .large,
                            leading: .init(resource: .qr)
                        ) {
                            viewModel.qr()
                        }
                        .frame(height: TextButton.Size.large.height)
                        .cornerRadius(28)
                        .accessibilityIdentifier("RecipientSearchView.loadedView.emptyRecipientsView.sqanQR")
                        
                        TextButtonView(
                            title: L10n.paste,
                            style: .primary,
                            size: .large,
                            leading: .init(resource: .paste)
                        ) {
                            viewModel.past()
                        }
                        .frame(height: TextButton.Size.large.height)
                        .cornerRadius(28)
                        .accessibilityIdentifier("RecipientSearchView.loadedView.emptyRecipientsView.pasteButton")
                    }.padding(.bottom, 8)
                }
            }
        }
        .padding(.top, 48)
    }

    private func okView(_ recipients: [Recipient]) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(L10n.hereSWhatWeFound)
                    .apply(style: .text4)
                    .foregroundColor(Color(.mountain))
                Spacer()
            }

            VStack(spacing: 24) {
                ForEach(recipients) { recipient in
                    VStack(spacing: 12) {
                        Button {
                            viewModel.selectRecipient(recipient)
                        } label: {
                            HStack {
                                RecipientCell(recipient: recipient)
                                Spacer()
                            }
                        }
                        .accessibilityIdentifier("RecipientSearchView.okView.recipientCell")

                        if recipient.category == .solanaAddress && !recipient.attributes.contains(.funds) {
                            HStack {
                                Image(.warning)
                                    .foregroundColor(Color(.sun))
                                Text(L10n.cautionThisAddressHasNoFunds)
                                    .apply(style: .label1)
                                Spacer()
                            }
                            .padding(.all, 14)
                            .background(
                                Color(.lightSun)
                                    .cornerRadius(radius: 8, corners: .allCorners)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                Color(.white)
                    .cornerRadius(radius: 16, corners: .allCorners)
            )

            // Continue anyway
            if
                recipients.count == 1,
                let recipient: Recipient = recipients.first,
                !recipient.attributes.contains(.funds),
                recipient.category != .ethereumAddress
            {
                VStack {
                    Spacer()
                    TextButtonView(title: L10n.continueAnyway, style: .primary, size: .large) {
                        viewModel.selectRecipient(recipient)
                    }
                    .frame(height: TextButton.Size.large.height)
                    .cornerRadius(28)
                    .accessibilityIdentifier("RecipientSearchView.okView.TextButtonView.recipient")
                }
            }
        }
    }
}

struct RecipientSearchView_Previews: PreviewProvider {
    static let okCase: RecipientSearchResult = .ok(
        [
            Recipient(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .username(name: "kirill", domain: "key"),
                attributes: [.funds]
            ),
            Recipient(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .username(name: "kirill2", domain: "sol"),
                attributes: [.funds]
            ),
        ]
    )

    static let okNoFundCase: RecipientSearchResult = .ok(
        [
            Recipient(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .solanaAddress,
                attributes: []
            ),
        ]
    )

    static let missingUserTokenResult: RecipientSearchResult = .missingUserToken(recipient: Recipient(
        address: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
        category: .solanaTokenAddress(
            walletAddress: try! .init(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
            token: .usdc
        ),
        attributes: [.funds]
    ))

    static var previews: some View {
        NavigationView {
            RecipientSearchView(
                viewModel: .init(
                    preChosenWallet: nil,
                    flow: .send,
                    recipientSearchService: RecipientSearchServiceMock(result: okNoFundCase),
                    sendHistoryService: SendHistoryService(provider: SendHistoryLocalProvider())
                )
            )
        }
    }
}
