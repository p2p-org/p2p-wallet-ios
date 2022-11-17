// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import Send

class RecipientSearchViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()

    @Published var input: String = ""
    @Published var result: RecipientSearchResult? = nil

    private let recipientSearchService: RecipientSearchService

    init(recipientSearchService: RecipientSearchService = Resolver.resolve()) {
        self.recipientSearchService = recipientSearchService

        $input.sinkAsync { [weak self] value in
            guard let self = self else { return }
            self.result = try await self.recipientSearchService.search(
                input: value,
                state: .init(wallets: [], exchangeRate: [:])
            )
        }.store(in: &subscriptions)
    }
}
