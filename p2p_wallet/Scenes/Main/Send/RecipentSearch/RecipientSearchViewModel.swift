// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Resolver
import Send

@MainActor
class RecipientSearchViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    
    @Injected private var clipboardManager: ClipboardManagerType

    @Published var input: String = ""
    @Published var result: RecipientSearchResult? = nil

    private let recipientSearchService: RecipientSearchService

    init(recipientSearchService: RecipientSearchService = Resolver.resolve()) {
        self.recipientSearchService = recipientSearchService

        $input.sinkAsync { [weak self] value in
            guard let self = self else { return }
            self.updateResult(result: await self.recipientSearchService.search(
                input: value,
                env: .init(wallets: [], exchangeRate: [:], tokens: [.nativeSolana, .usdc, .usdt])
            ))
        }.store(in: &subscriptions)
    }
    
    func updateResult(result: RecipientSearchResult) {
        self.result = result
    }
    
    func past() {
        guard let text = clipboardManager.stringFromClipboard() else { return }
        input = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func qr() {}
}
