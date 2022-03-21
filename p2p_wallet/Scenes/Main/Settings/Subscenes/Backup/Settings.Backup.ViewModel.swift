//
//  Settings.Backup.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/03/2022.
//

import Foundation
import RxCocoa

protocol SettingsBackupViewModelType {
    var navigationDriver: Driver<Settings.Backup.NavigatableScene?> {get}
    var didBackupDriver: Driver<Bool> { get }
    func backupUsingICloud()
    func backupManually()
    func setDidBackupOffline()
    
    func navigate(to scene: Settings.Backup.NavigatableScene)
}

extension Settings.Backup {
    final class ViewModel {
        @Injected private var storage: ICloudStorageType & AccountStorageType & NameStorageType
        @Injected private var authenticationHandler: AuthenticationHandlerType
        @Injected private var deviceOwnerAuthenticationHandler: DeviceOwnerAuthenticationHandler
        @Injected private var notificationsService: NotificationsServiceType
        var didBackupHandler: (() -> Void)?
        
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private lazy var didBackupSubject = BehaviorRelay<Bool>(value: storage.didBackupUsingIcloud || Defaults.didBackupOffline)
    }
}

extension Settings.Backup.ViewModel: SettingsBackupViewModelType {
    var navigationDriver: Driver<Settings.Backup.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var didBackupDriver: Driver<Bool> {
        didBackupSubject.asDriver()
    }
    
    func backupManually() {
        if didBackupSubject.value {
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
        navigationSubject.accept(scene)
    }
    
    func setDidBackupOffline() {
        Defaults.didBackupOffline = true
        setDidBackup(true)
    }
    
    func setDidBackup(_ didBackup: Bool) {
        didBackupSubject.accept(didBackup)
        didBackupHandler?()
    }
}
