// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

class HistoryCoordinator: SmartCoordinator<Void> {
    override func build() -> UIViewController {
        let scene = History.Scene()

        scene.viewModel.onTapPublisher
            .sink { [weak self] _ in }
            .store(in: &subscriptions)

        return scene
    }

    private func showSellTransaction(transaction _: SellDataServiceTransaction) {}
}
