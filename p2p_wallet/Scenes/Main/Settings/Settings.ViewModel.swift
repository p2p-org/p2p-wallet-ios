//
//  Settings.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Foundation
import RxSwift
import RxCocoa
import LocalAuthentication

protocol SettingsViewModelType {
    var navigationDriver: Driver<Settings.NavigatableScene?> {get}
    var usernameDriver: Driver<String?> {get}
    var didBackupDriver: Driver<Bool> {get}
    var fiatDriver: Driver<Fiat> {get}
    var endpointDriver: Driver<SolanaSDK.APIEndPoint> {get}
    var securityMethodsDriver: Driver<[String]> {get}
    var currentLanguageDriver: Driver<String?> {get}
    var themeDriver: Driver<UIUserInterfaceStyle?> {get}
    var hideZeroBalancesDriver: Driver<Bool> {get}
    var logoutAlertSignal: Signal<Void> {get}
    
    func navigate(to scene: Settings.NavigatableScene)
    func setDidBackup(_ didBackup: Bool)
    func setFiat(_ fiat: Fiat)
    func setApiEndpoint(_ endpoint: SolanaSDK.APIEndPoint)
    func setEnabledBiometry(_ enabledBiometry: Bool)
    func setLanguage(_ language: String?)
    func setTheme(_ theme: UIUserInterfaceStyle?)
    func setHideZeroBalances(_ hideZeroBalances: Bool)
    
    func showLogoutAlert()
    func logout()
}

extension Settings {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var rootViewModel: RootViewModelType
        
        // MARK: - Properties
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private lazy var usernameSubject = BehaviorRelay<String?>(value: accountStorage.getName())
        private lazy var didBackupSubject = BehaviorRelay<Bool>(value: accountStorage.didBackupUsingIcloud || Defaults.didBackupOffline)
        private let fiatSubject = BehaviorRelay<Fiat>(value: Defaults.fiat)
        private let endpointSubject = BehaviorRelay<SolanaSDK.APIEndPoint>(value: Defaults.apiEndPoint)
        private lazy var securityMethodsSubject = BehaviorRelay<[String]>(value: getSecurityMethods())
        private let currentLanguageSubject = BehaviorRelay<String?>(value: Locale.current.uiLanguageLocalizedString?.uppercaseFirst)
        private let themeSubject = BehaviorRelay<UIUserInterfaceStyle?>(value: AppDelegate.shared.window?.overrideUserInterfaceStyle)
        private let hideZeroBalancesSubject = BehaviorRelay<Bool>(value: Defaults.hideZeroBalances)
        private let logoutAlertSubject = PublishRelay<Void>()
        
        // MARK: - Methods
        private func getSecurityMethods() -> [String] {
            var methods: [String] = []
            if Defaults.isBiometryEnabled {
                methods.append(LABiometryType.current.stringValue)
            }
            methods.append(L10n.pinCode)
            return methods
        }
    }
}

extension Settings.ViewModel: SettingsViewModelType {
    var navigationDriver: Driver<Settings.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var usernameDriver: Driver<String?> {
        usernameSubject.asDriver()
    }
    
    var didBackupDriver: Driver<Bool> {
        didBackupSubject.asDriver()
    }
    
    var fiatDriver: Driver<Fiat> {
        fiatSubject.asDriver()
    }
    
    var endpointDriver: Driver<SolanaSDK.APIEndPoint> {
        endpointSubject.asDriver()
    }
    
    var securityMethodsDriver: Driver<[String]> {
        securityMethodsSubject.asDriver()
    }
    
    var currentLanguageDriver: Driver<String?> {
        currentLanguageSubject.asDriver()
    }
    
    var themeDriver: Driver<UIUserInterfaceStyle?> {
        themeSubject.asDriver()
    }
    
    var hideZeroBalancesDriver: Driver<Bool> {
        hideZeroBalancesSubject.asDriver()
    }
    
    var logoutAlertSignal: Signal<Void> {
        logoutAlertSubject.asSignal()
    }
    
    // MARK: - Actions
    func navigate(to scene: Settings.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func setDidBackup(_ didBackup: Bool) {
        didBackupSubject.accept(didBackup)
    }
    
    func setFiat(_ fiat: Fiat) {
        fiatSubject.accept(fiat)
    }
    
    func setApiEndpoint(_ endpoint: SolanaSDK.APIEndPoint) {
        endpointSubject.accept(endpoint)
    }
    
    func setEnabledBiometry(_ enabledBiometry: Bool) {
        securityMethodsSubject.accept(getSecurityMethods())
    }
    
    func setLanguage(_ language: String?) {
        
    }
    
    func setTheme(_ theme: UIUserInterfaceStyle?) {
        
    }
    
    func setHideZeroBalances(_ hideZeroBalances: Bool) {
        Defaults.hideZeroBalances.toggle()
        analyticsManager.log(event: .settingsHideBalancesClick(hide: Defaults.hideZeroBalances))
    }
    
    func showLogoutAlert() {
        logoutAlertSubject.accept(())
    }
    
    func logout() {
        analyticsManager.log(event: .settingsLogoutClick)
        rootViewModel.logout()
    }
}
