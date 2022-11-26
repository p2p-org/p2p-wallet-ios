// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import Send
import SwiftUI

struct RecipientSearchView: View {
    @ObservedObject var viewModel: RecipientSearchViewModel

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Search field
                RecipientSearchField(text: $viewModel.input) {
                    viewModel.past()
                } scan: {
                    viewModel.qr()
                }

                // Result
                if let result = viewModel.result {
                    switch result {
                    case let .ok(recipients):
                        VStack(alignment: .leading) {
                            HStack {
                                Text(L10n.hereSWhatWeFound)
                                    .apply(style: .text4)
                                    .foregroundColor(Color(Asset.Colors.mountain.color))
                                Spacer()
                            }
                            
                            VStack(spacing: 24) {
                                ForEach(recipients) { recipient in
                                    Button {
                                        
                                    } label: {
                                        HStack {
                                            RecipientCell(recipient: recipient)
                                            Spacer()
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
                    default:
                        SwiftUI.EmptyView()
                    }
                } else {
                    // History
                    Text("History")
                }
                Spacer()
            }
            .padding(.all, 16)
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
}

struct RecipientSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecipientSearchView(
                viewModel: .init(
                    recipientSearchService: RecipientSearchServiceMock(
                        result: .ok(
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
                    )
                )
            )
        }
    }
}
