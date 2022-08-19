// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import Resolver

class ICloudRestoreViewModel: BaseViewModel {
    // MARK: - Declarations

    typealias SeedPhrase = String

    struct CoordinatorIO {
        let back: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let info: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let restore: PassthroughSubject<ReactiveProcess<ICloudAccount>, Never> = .init()
    }

    // MARK: - Services

    @Injected var notificationService: NotificationService

    // MARK: - Coordinator

    private(set) var coordinatorIO: CoordinatorIO = .init()

    // MARK: - States

    @Published var loading: Bool = false
    @Published var accounts: [ICloudAccount] = []

    // MARK: - Events

    init(accounts: [ICloudAccount]) {
        self.accounts = accounts
        super.init()
    }

    func back() {
        guard loading == false else { return }
        loading = true

        coordinatorIO.back.sendProcess { [weak self] error in
            if let error = error { self?.notificationService.showDefaultErrorNotification() }
            self?.loading = false
        }
    }

    func info() {
        guard loading == false else { return }
        loading = true

        coordinatorIO.info.sendProcess { [weak self] error in
            if let error = error { self?.notificationService.showDefaultErrorNotification() }
            self?.loading = false
        }
    }

    func restore(account: ICloudAccount) {
        guard loading == false else { return }
        loading = true

        coordinatorIO.restore.sendProcess(data: account) { [weak self] error in
            if let error = error { self?.notificationService.showDefaultErrorNotification() }
            self?.loading = false
        }
    }
}

extension ICloudAccount: Identifiable {
    public var id: String { publicKey }
}
