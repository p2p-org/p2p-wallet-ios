// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import LocalAuthentication
import Onboarding
import Resolver

class ICloudRestoreViewModel: BaseViewModel {
    // MARK: - Declarations

    typealias SeedPhrase = String

    // MARK: - Services

    @Injected private var notificationService: NotificationService
    @Injected private var biometricsProvider: BiometricsAuthProvider

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

        back.sendProcess { [weak self] error in
            if error != nil { self?.notificationService.showDefaultErrorNotification() }
            self?.loading = false
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

        biometricsProvider.authenticate { [weak self] success, authError in
            guard let self = self else { return }
            if success || self.canBeSkipped(error: authError) {
                self.restore.sendProcess(data: account) { error in
                    if error != nil { self.notificationService.showDefaultErrorNotification() }
                    self.loading = false
                }
            } else if authError?.code == LAError.biometryLockout.rawValue {
                self.notificationService.showDefaultErrorNotification()
                self.loading = false
            } else {
                self.loading = false
            }
        }
    }

    private func canBeSkipped(error: NSError?) -> Bool {
        guard let error = error else { return true }
        switch error.code {
        case LAError.biometryNotEnrolled.rawValue:
            return true
        case LAError.biometryNotAvailable.rawValue:
            return true
        default:
            return false
        }
    }
}

extension ICloudAccount: Identifiable {
    public var id: String { publicKey }
}
