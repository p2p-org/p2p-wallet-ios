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

protocol ChangeLanguageResponder {
    func languageDidChange(to: LocalizedLanguage)
}

protocol ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint)
}

protocol ChangeFiatResponder {
    func changeFiat(to fiat: Fiat)
}

protocol SettingsViewModelType {
    var selectableLanguages: [LocalizedLanguage: Bool] { get }
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
    
    func getUserAddress() -> String?
    
    func navigate(to scene: Settings.NavigatableScene)
    func showOrReserveUsername()
    func backupUsingICloud()
    func backupManually()
    func setDidBackupOffline()
    func setDidBackup(_ didBackup: Bool)
    func setFiat(_ fiat: Fiat)
    func setApiEndpoint(_ endpoint: SolanaSDK.APIEndPoint)
    func setEnabledBiometry(_ enabledBiometry: Bool, onError: @escaping (Error?) -> Void)
    func changePincode()
    func savePincode(_ pincode: String)
    func setLanguage(_ language: LocalizedLanguage)
    func setTheme(_ theme: UIUserInterfaceStyle)
    func setHideZeroBalances(_ hideZeroBalances: Bool)
    
    func showLogoutAlert()
    func copyUsernameToClipboard()
    func shareUsername()
    func logout()
}

extension Settings {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var rootViewModel: RootViewModelType
        private var reserveNameHandler: ReserveNameHandler
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var changeNetworkResponder: ChangeNetworkResponder
        @Injected private var changeLanguageResponder: ChangeLanguageResponder
        @Injected private var localizationManager: LocalizationManagerType
        let changeFiatResponder: ChangeFiatResponder
        let renVMService: RenVMLockAndMintServiceType
        
        // MARK: - Properties
        private var disposables = [DefaultsDisposable]()
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private lazy var usernameSubject = BehaviorRelay<String?>(value: accountStorage.getName()?.withNameServiceDomain())
        private lazy var didBackupSubject = BehaviorRelay<Bool>(value: accountStorage.didBackupUsingIcloud || Defaults.didBackupOffline)
        private let fiatSubject = BehaviorRelay<Fiat>(value: Defaults.fiat)
        private let endpointSubject = BehaviorRelay<SolanaSDK.APIEndPoint>(value: Defaults.apiEndPoint)
        private lazy var securityMethodsSubject = BehaviorRelay<[String]>(value: getSecurityMethods())
        private let currentLanguageSubject = BehaviorRelay<String?>(value: Locale.current.uiLanguageLocalizedString?.uppercaseFirst)
        private let themeSubject = BehaviorRelay<UIUserInterfaceStyle?>(value: AppDelegate.shared.window?.overrideUserInterfaceStyle)
        private let hideZeroBalancesSubject = BehaviorRelay<Bool>(value: Defaults.hideZeroBalances)
        private let logoutAlertSubject = PublishRelay<Void>()
        
        // MARK: - Initializer
        init(
            reserveNameHandler: ReserveNameHandler,
            changeFiatResponder: ChangeFiatResponder,
            renVMService: RenVMLockAndMintServiceType
        ) {
            self.reserveNameHandler = reserveNameHandler
            self.changeFiatResponder = changeFiatResponder
            self.renVMService = renVMService
            bind()
        }
        
        func bind() {
            disposables.append(Defaults.observe(\.forceCloseNameServiceBanner) {[weak self] _ in
                self?.usernameSubject.accept(self?.accountStorage.getName()?.withNameServiceDomain())
            })
        }
        
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
    var selectableLanguages: [LocalizedLanguage: Bool] {
        localizationManager.selectableLanguages()
    }

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
    
    func getUserAddress() -> String? {
        accountStorage.account?.publicKey.base58EncodedString
    }
    
    // MARK: - Actions
    func navigate(to scene: Settings.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func showOrReserveUsername() {
        if accountStorage.getName() != nil {
            navigate(to: .username)
        } else if let owner = accountStorage.account?.publicKey.base58EncodedString {
            navigate(to: .reserveUsername(owner: owner, handler: reserveNameHandler))
        }
    }
    
    func backupUsingICloud() {
        guard let account = accountStorage.account?.phrase else {return}
        authenticationHandler.authenticate(
            presentationStyle: .init(
                isRequired: false,
                isFullScreen: false,
                completion: { [weak self] in
                    guard let self = self else {return}
                    self.accountStorage.saveToICloud(
                        account: .init(
                            name: self.accountStorage.getName(),
                            phrase: account.joined(separator: " "),
                            derivablePath: self.accountStorage.getDerivablePath() ?? .default
                        )
                    )
                    self.setDidBackup(true)
                }
            )
        )
    }
    
    func backupManually() {
        if didBackupSubject.value {
            authenticationHandler.authenticate(
                presentationStyle: .init(
                    isRequired: false,
                    isFullScreen: false,
                    completion: { [weak self] in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            self?.navigate(to: .backupShowPhrases)
                        }
                    }
                )
            )
        } else {
            navigate(to: .backupManually)
        }
    }
    
    func setDidBackupOffline() {
        Defaults.didBackupOffline = true
        setDidBackup(true)
    }
    
    func setDidBackup(_ didBackup: Bool) {
        didBackupSubject.accept(didBackup)
    }
    
    func setFiat(_ fiat: Fiat) {
        analyticsManager.log(event: .settingsСurrencySelected(сurrency: fiat.code))
        changeFiatResponder.changeFiat(to: fiat)
        fiatSubject.accept(fiat)
        UIApplication.shared.showToast(message: "✅ " + L10n.currencyChanged)
    }
    
    func setApiEndpoint(_ endpoint: SolanaSDK.APIEndPoint) {
        endpointSubject.accept(endpoint)
        
        analyticsManager.log(event: .settingsNetworkSelected(network: endpoint.address))
        if Defaults.apiEndPoint.network != endpoint.network {
            renVMService.expireCurrentSession()
        }
        
        changeNetworkResponder.changeAPIEndpoint(to: endpoint)
    }
    
    func setEnabledBiometry(_ enabledBiometry: Bool, onError: @escaping (Error?) -> Void) {
        // pause authentication
        authenticationHandler.pauseAuthentication(true)
        
        // get context
        let context = LAContext()
        let reason = L10n.identifyYourself

        // evaluate Policy
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, authenticationError) in
            DispatchQueue.main.async { [weak self] in
                if success {
                    Defaults.isBiometryEnabled.toggle()
                    self?.analyticsManager.log(event: .settingsSecuritySelected(faceId: Defaults.isBiometryEnabled))
                    self?.securityMethodsSubject.accept(self?.getSecurityMethods() ?? [])
                } else {
                    onError(authenticationError)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.authenticationHandler.pauseAuthentication(false)
            }
        }
    }
    
    func changePincode() {
        authenticationHandler.authenticate(
            presentationStyle: .init(
                title: L10n.enterCurrentPINCode,
                isRequired: false,
                isFullScreen: false,
                useBiometry: false,
                completion: { [weak self] in
                    // pin code vc
                    self?.navigate(to: .changePincode)
                }
            )
        )
    }
    
    func savePincode(_ pincode: String) {
        accountStorage.save(pincode)
    }
    
    func setLanguage(_ language: LocalizedLanguage) {
        localizationManager.changeCurrentLanguage(language)
        changeLanguageResponder.languageDidChange(to: language)
    }
    
    func setTheme(_ theme: UIUserInterfaceStyle) {
        themeSubject.accept(theme)
        analyticsManager.log(event: .settingsAppearanceSelected(appearance: theme.name))
        AppDelegate.shared.changeThemeTo(theme)
    }
    
    func setHideZeroBalances(_ hideZeroBalances: Bool) {
        Defaults.hideZeroBalances.toggle()
        analyticsManager.log(event: .settingsHideBalancesClick(hide: Defaults.hideZeroBalances))
        hideZeroBalancesSubject.accept(hideZeroBalances)
    }
    
    func showLogoutAlert() {
        logoutAlertSubject.accept(())
    }
    
    func copyUsernameToClipboard() {
        guard let username = accountStorage.getName()?.withNameServiceDomain() else {return}
        UIApplication.shared.copyToClipboard(username, alert: true, alertMessage: L10n.copiedToClipboard)
    }
    
    func shareUsername() {
        guard let username = accountStorage.getName()?.withNameServiceDomain() else {return}
        navigate(to: .share(item: username))
    }
    
    func logout() {
        analyticsManager.log(event: .settingsLogoutClick)
        rootViewModel.logout()
    }
}
