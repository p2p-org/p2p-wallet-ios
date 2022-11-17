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

            VStack {
                TextField("Username or address", text: $viewModel.input)
                    .padding(.all, 8)

                if let result = viewModel.result {
                    switch result {
                    case let .ok(recipients):
                        VStack(alignment: .leading) {
                            Text("Here's what found")
                            Group {
                                ForEach(recipients, id: \.address) { recipient in
                                    VStack {
                                        Text(recipient.address)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.all, 8)
                            .background(
                                Color(.white)
                                    .cornerRadius(radius: 16, corners: .allCorners)
                            )
                        }
                        

                    default:
                        Text("Undefined")
                    }
                } else {
                    // History
                    Text("History")
                }

                Spacer()
            }
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
                                    hasFunds: true
                                ),
                            ]
                        )
                    )
                )
            )
        }
    }
}
