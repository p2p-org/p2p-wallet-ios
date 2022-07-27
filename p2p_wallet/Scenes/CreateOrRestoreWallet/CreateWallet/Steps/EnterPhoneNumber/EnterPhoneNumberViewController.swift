// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import CountriesAPI
import Foundation
import KeyAppUI

final class EnterPhoneNumberViewController: BaseViewController {
    let sol: String
    let eth: String
    let deviceShare: String

    var subscriptions = [AnyCancellable]()

    let currentFlag: CurrentValueSubject<Country?, Never> = .init(nil)
    let onFlagSelection: PassthroughSubject<Void, Never> = .init()

    init(sol: String, eth: String, deviceShare: String) {
        self.sol = sol
        self.eth = eth
        self.deviceShare = deviceShare

        super.init()
    }

    override func build() -> UIView {
        BECenter {
            UILabel(text: "Enter phone number screen")
            UILabel(text: sol)
            UILabel(text: eth)
            UILabel(text: deviceShare)
            TextButton(title: "Select country", style: .primary, size: .large)
                .onPressed { [weak self] _ in self?.onFlagSelection.send() }
                .setup { view in
                    currentFlag.sink { [weak view] country in
                        view?.title = country?.name ?? "Select country"
                    }.store(in: &subscriptions)
                }
        }
    }
}
