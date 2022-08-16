//
//  Settings.Backup.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/03/2022.
//

import Combine
import Foundation
import Resolver

protocol SettingsBackupViewModelType {
    var navigatableScenePublisher: AnyPublisher<Settings.Backup.NavigatableScene?, Never> { get }
    var didBackupPublisher: AnyPublisher<Bool, Never> { get }
    func backupUsingICloud()
    func backupManually()
    func setDidBackupOffline()
}

extension Settings.Backup {
    final class ViewModel: BaseViewModel {
        @Injected private var storage: ICloudStorageType & AccountStorageType & NameStorageType
        @Injected private var authenticationHandler: AuthenticationHandlerType
        @Injected private var deviceOwnerAuthenticationHandler: DeviceOwnerAuthenticationHandler
        @Injected private var notificationsService: NotificationService
        var didBackupHandler: (() -> Void)?

        @Published private var navigatableScene: NavigatableScene?
        @Published private var didBackup: Bool = false

        override init() {
            super.init()
            didBackup = storage.didBackupUsingIcloud || Defaults
                .didBackupOffline
        }
    }
}

extension Settings.Backup.ViewModel: SettingsBackupViewModelType {
    var navigatableScenePublisher: AnyPublisher<Settings.Backup.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var didBackupPublisher: AnyPublisher<Bool, Never> {
        $didBackup.eraseToAnyPublisher()
    }

    func backupManually() {
        if didBackup {
            authenticationHandler.pauseAuthentication(true)
            deviceOwnerAuthenticationHandler.requiredOwner(onSuccess: {
                self.navigate(to: .showPhrases)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.authenticationHandler.pauseAuthentication(false)
                }
            }, onFailure: { error in
                guard let error = error else { return }
                self.notificationsService.showInAppNotification(.error(error))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.authenticationHandler.pauseAuthentication(false)
                }
            })
        } else {
            navigate(to: .backupManually)
        }
    }

    func backupUsingICloud() {
        guard let account = storage.account?.phrase else { return }
        authenticationHandler.pauseAuthentication(true)

        deviceOwnerAuthenticationHandler.requiredOwner(onSuccess: {
            _ = self.storage.saveToICloud(
                account: .init(
                    name: self.storage.getName(),
                    phrase: account.joined(separator: " "),
                    derivablePath: self.storage.getDerivablePath() ?? .default
                )
            )
            self.setDidBackup(true)
            self.notificationsService.showInAppNotification(.done(L10n.savedToICloud))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.authenticationHandler.pauseAuthentication(false)
            }
        }, onFailure: { error in
            guard let error = error else { return }
            self.notificationsService.showInAppNotification(.error(error))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.authenticationHandler.pauseAuthentication(false)
            }
        })
    }

    func navigate(to scene: Settings.Backup.NavigatableScene) {
        navigatableScene = scene
    }

    func setDidBackupOffline() {
        Defaults.didBackupOffline = true
        setDidBackup(true)
    }

    func setDidBackup(_ didBackup: Bool) {
        self.didBackup = didBackup
        didBackupHandler?()
    }
}
