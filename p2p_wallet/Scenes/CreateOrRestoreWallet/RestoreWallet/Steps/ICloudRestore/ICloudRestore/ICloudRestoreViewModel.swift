// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import Resolver

final class ICloudRestoreViewModel: BaseICloudRestoreViewModel {
    // MARK: - Declarations

    typealias SeedPhrase = String

    // MARK: - Output events

    let back: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
    let info: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
    let restore: PassthroughSubject<ReactiveProcess<ICloudAccount>, Never> = .init()

    // MARK: - States

    @Published var loading: Bool = false
    @Published var accounts: [ICloudAccount] = []

    // MARK: - Events

    init(accounts: [ICloudAccount]) {
        self.accounts = accounts
        super.init()
    }

    func backPressed() {
        guard loading == false else { return }
        loading = true

        back.sendProcess { error in
            DispatchQueue.main.async { [weak self] in
                if error != nil { self?.notificationService.showDefaultErrorNotification() }
                self?.loading = false
            }
        }
    }

    func infoPressed() {
        guard loading == false else { return }
        loading = true

        info.sendProcess { [weak self] error in
            if error != nil { self?.notificationService.showDefaultErrorNotification() }
            self?.loading = false
        }
    }

    func restore(account: ICloudAccount) {
        guard loading == false else { return }
        loading = true
        authenticate { [weak self] success in
            guard let self = self else { return }
            if success {
                self.restore.sendProcess(data: account) { error in
                    DispatchQueue.main.async { [weak self] in
                        if error != nil { self?.notificationService.showDefaultErrorNotification() }
                        self?.loading = false
                    }
                }
            } else {
                self.loading = false
            }
        }
    }
}

extension ICloudAccount: Identifiable {
    public var id: String { publicKey }
}
