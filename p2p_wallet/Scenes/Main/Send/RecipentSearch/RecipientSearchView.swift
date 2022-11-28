// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import Send
import SwiftUI

struct RecipientSearchView: View {
    @ObservedObject var viewModel: RecipientSearchViewModel
    @SwiftUI.Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Search field
                RecipientSearchField(text: $viewModel.input, isLoading: $viewModel.isSearching) {
                    viewModel.past()
                } scan: {
                    viewModel.qr()
                }

                // Result
                if let result = viewModel.searchResult {
                    switch result {
                    case let .ok(recipients):
                        // Ok case
                        if recipients.isEmpty {
                            // Not found
                            RecipientNotFoundView()
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
                    case .nameServiceError:
                        tryLater(title: L10n.solanaNameServiceDoesnTRespond)
                            .padding(.top, 38)
                            .padding(.horizontal, 12)
                    case .solanaServiceError:
                        tryLater(title: "Solana Service doesn't respond")
                            .padding(.top, 38)
                            .padding(.horizontal, 12)
                    }
                } else {
                    // History
                    history(viewModel.recipientsHistory)
                }
                Spacer()
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .toolbar {
                // Navigation title
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Choose recipient")
                        Text("Solana & Bitcoin network")
                            .apply(style: .label1)
                    }
                }
            }
        }
    }

    func tryLater(title: String) -> some View {
        VStack(alignment: .center, spacing: 28) {
            Image(uiImage: Asset.Icons.warning.image)
                .foregroundColor(Color(Asset.Colors.rose.color))
            Text(title)
                .apply(style: .text3)
            Text(L10n.weSuggestYouTryAgainLaterBecauseWeWillNotBeAbleToVerifyTheAddressIfYouContinue)
                .apply(style: .text3)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(Color(Asset.Colors.night.color))
    }

    func disabledAndReason(_ recipient: Recipient, reason: String) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                Text(L10n.hereSWhatWeFound)
                    .apply(style: .text4)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                Spacer()
            }

            RecipientCell(recipient: recipient)
                .disabled(true)

            Text(reason)
                .apply(style: .text4)
                .foregroundColor(Color(Asset.Colors.rose.color))
        }
    }

    func history(_ recipients: [Recipient]) -> some View {
        Group {
            if recipients.isEmpty {
                VStack(spacing: 16) {
                    Text(L10n.makeYourFirstTransaction)
                        .fontWeight(.bold)
                        .apply(style: .title2)
                    Text(L10n.toContinuePasteOrScanTheAddressOrTypeAUsername)
                        .apply(style: .text1)
                        .multilineTextAlignment(.center)
                }.padding(.top, 48)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(L10n.recentlyUsed)
                                .apply(style: .text4)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                            Spacer()
                        }

                        VStack(spacing: 24) {
                            ForEach(recipients) { recipient in
                                VStack(spacing: 12) {
                                    Button {} label: {
                                        HStack {
                                            RecipientCell(recipient: recipient)
                                            Spacer()
                                        }
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
                    }
                }
            }
        }
    }

    func okView(_ recipients: [Recipient]) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(L10n.hereSWhatWeFound)
                    .apply(style: .text4)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                Spacer()
            }

            VStack(spacing: 24) {
                ForEach(recipients) { recipient in
                    VStack(spacing: 12) {
                        Button {} label: {
                            HStack {
                                RecipientCell(recipient: recipient)
                                Spacer()
                            }
                        }

                        if recipient.category == .solanaAddress && !recipient.attributes.contains(.funds) {
                            HStack {
                                Image(uiImage: Asset.Icons.warning.image)
                                    .foregroundColor(Color(Asset.Colors.sun.color))
                                Text(L10n.cautionThisAddressHasNoFunds)
                                    .apply(style: .label1)
                                Spacer()
                            }
                            .padding(.all, 14)
                            .background(
                                Color(Asset.Colors.lightSun.color)
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
                    recipientSearchService: RecipientSearchServiceMock(
                        result: okNoFundCase
                    ),
                    sendHistoryService: SendHistoryService(
                        localProvider: SendHistoryLocalProvider(),
                        remoteProvider: SendHistoryRemoteMockProvider(recipients: [
                            .init(
                                address: "8upjSpvjcdpuzhfR1zriwg5NXkwDruejqNE9WNbPRtyA",
                                category: .solanaAddress,
                                attributes: []
                            ),
                        ])
                    )
                )
            )
        }
    }
}
