//
//  Settings.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import AnalyticsManager
import Foundation
import LocalAuthentication
import RenVMSwift
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol ChangeLanguageResponder {
    func languageDidChange(to: LocalizedLanguage)
}

protocol ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: APIEndPoint)
}

protocol LogoutResponder {
    func logout()
}

protocol SettingsViewModelType: ReserveNameHandler {
    var selectableLanguages: [(LocalizedLanguage, Bool)] { get }
    var navigationDriver: Driver<Settings.NavigatableScene?> { get }
    var usernameDriver: Driver<String?> { get }
    var didBackupDriver: Driver<Bool> { get }
    var fiatDriver: Driver<Fiat> { get }
    var hideZeroBalancesDriver: Driver<Bool> { get }
    var logoutAlertSignal: Signal<Void> { get }
    var biometryTypeDriver: Driver<Settings.BiometryType> { get }
    var isBiometryEnabledDriver: Driver<Bool> { get }
    var isBiometryAvailableDriver: Driver<Bool> { get }

    func getUserAddress() -> String?
    func getUsername() -> String?

    func navigate(to scene: Settings.NavigatableScene)
    func showOrReserveUsername()
    func setDidBackup(_ didBackup: Bool)
    func setFiat(_ fiat: Fiat)
    func setApiEndpoint(_ endpoint: APIEndPoint)
    func setEnabledBiometry(_ enabledBiometry: Bool, onError: @escaping (Error?) -> Void)
    func changePincode()
    func savePincode(_ pincode: String)
    func setLanguage(_ language: LocalizedLanguage)
    func setTheme(_ theme: UIUserInterfaceStyle)
    func setHideZeroBalances(_ hideZeroBalances: Bool)

    func showLogoutAlert()
    func copyUsernameToClipboard()
    func share(image: UIImage)
    func saveImage(image: UIImage)
    func logout()
}

extension Settings {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var storage: ICloudStorageType & AccountStorageType & NameStorageType & PincodeStorageType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var logoutResponder: LogoutResponder
        @Injected private var authenticationHandler: AuthenticationHandlerType
        @Injected private var changeNetworkResponder: ChangeNetworkResponder
        @Injected private var changeLanguageResponder: ChangeLanguageResponder
        @Injected private var localizationManager: LocalizationManagerType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected var notificationsService: NotificationService
        @Injected private var pricesService: PricesServiceType
        @Injected private var renVMService: LockAndMintService
        @Injected private var imageSaver: ImageSaverType

        // MARK: - Properties

        private var disposables = [DefaultsDisposable]()
        private let disposeBag = DisposeBag()

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private lazy var usernameSubject = BehaviorRelay<String?>(value: storage.getName())
        private lazy var didBackupSubject = BehaviorRelay<Bool>(value: storage.didBackupUsingIcloud || Defaults
            .didBackupOffline)
        private let fiatSubject = BehaviorRelay<Fiat>(value: Defaults.fiat)
        private let endpointSubject = BehaviorRelay<APIEndPoint>(value: Defaults.apiEndPoint)
        private lazy var securityMethodsSubject = BehaviorRelay<[String]>(value: getSecurityMethods())
        private let themeSubject = BehaviorRelay<UIUserInterfaceStyle?>(value: AppDelegate.shared.window?
            .overrideUserInterfaceStyle)
        private let hideZeroBalancesSubject = BehaviorRelay<Bool>(value: Defaults.hideZeroBalances)
        private let biometryTypeSubject = BehaviorRelay<BiometryType>(value: .face)
        private let isBiometryEnabledSubject = BehaviorRelay<Bool>(value: Defaults.isBiometryEnabled)
        private let isBiometryAvailableSubject = BehaviorRelay<Bool>(value: false)
        private let logoutAlertSubject = PublishRelay<Void>()

        // MARK: - Initializer

        init() {
            setUp()
            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        // MARK: - Methods

        func setUp() {
            let context = LAContext()
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                isBiometryAvailableSubject.accept(true)
            }

            switch context.biometryType {
            case .faceID:
                biometryTypeSubject.accept(.face)
            case .touchID:
                biometryTypeSubject.accept(.touch)
            default:
                biometryTypeSubject.accept(.none)
            }
        }

        func bind() {
            disposables.append(Defaults.observe(\.forceCloseNameServiceBanner) { [weak self] _ in
                self?.usernameSubject.accept(self?.storage.getName())
            })

            storage
                .onValueChange
                .emit(onNext: { [weak self] event in
                    if event.key == "getName", let name = event.value as? String {
                        self?.usernameSubject.accept(name)
                    }
                })
                .disposed(by: disposeBag)
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
    var selectableLanguages: [(LocalizedLanguage, Bool)] {
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

    var hideZeroBalancesDriver: Driver<Bool> {
        hideZeroBalancesSubject.asDriver()
    }

    var logoutAlertSignal: Signal<Void> {
        logoutAlertSubject.asSignal()
    }

    func getUserAddress() -> String? {
        storage.account?.publicKey.base58EncodedString
    }

    func getUsername() -> String? {
        storage.getName()
    }

    // MARK: - Actions

    func navigate(to scene: Settings.NavigatableScene) {
        navigationSubject.accept(scene)
    }

    func showOrReserveUsername() {
        if storage.getName() != nil {
            navigate(to: .username)
        } else {
            navigate(to: .reserveUsername)
        }
    }

    func setDidBackup(_ didBackup: Bool) {
        didBackupSubject.accept(didBackup)
    }

    func setFiat(_ fiat: Fiat) {
        analyticsManager.log(event: .settingsСurrencySelected(сurrency: fiat.code))
        // set default fiat
        Defaults.fiat = fiat
        pricesService.clearCurrentPrices()
        pricesService.fetchAllTokensPriceInWatchList()

        // accept new value
        fiatSubject.accept(fiat)
        notificationsService.showInAppNotification(.done(L10n.currencyChanged))
    }

    func setApiEndpoint(_ endpoint: APIEndPoint) {
        guard Defaults.apiEndPoint != endpoint else { return }
        endpointSubject.accept(endpoint)
        analyticsManager.log(event: .networkChanging(networkName: endpoint.address))
        Task {
            try await renVMService.expireCurrentSession()
            await MainActor.run {
                changeNetworkResponder.changeAPIEndpoint(to: endpoint)
            }
        }
    }

    var isBiometryEnabledDriver: Driver<Bool> { isBiometryEnabledSubject.asDriver() }

    var isBiometryAvailableDriver: Driver<Bool> { isBiometryAvailableSubject.asDriver() }

    var biometryTypeDriver: Driver<Settings.BiometryType> { biometryTypeSubject.asDriver() }

    func handleName(_ name: String?) {
        guard let name = name else { return }
        storage.save(name: name)
    }

    func setEnabledBiometry(_: Bool, onError: @escaping (Error?) -> Void) {
        // pause authentication
        authenticationHandler.pauseAuthentication(true)

        // get context
        let context = LAContext()
        let reason = L10n.identifyYourself

        // evaluate Policy
        context
            .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                            localizedReason: reason)
            { success, authenticationError in
                DispatchQueue.main.async { [weak self] in
                    if success {
                        Defaults.isBiometryEnabled.toggle()
                        self?.isBiometryEnabledSubject.accept(Defaults.isBiometryEnabled)
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
                title: L10n.enterCurrentPIN,
                options: [.fullscreen, .disableBiometric, .withResetPassword],
                completion: { [weak self] passwordReset in
                    guard !passwordReset else {
                        self?.notificationsService.showInAppNotification(.done(L10n.youHaveSuccessfullySetYourPIN))
                        return
                    }
                    // pin code vc
                    self?.navigate(to: .changePincode)
                }
            )
        )
    }

    func savePincode(_ pincode: String) {
        storage.save(pincode)
    }

    func setLanguage(_ language: LocalizedLanguage) {
        localizationManager.changeCurrentLanguage(language)
        analyticsManager.log(event: .settingsLanguageSelected(language: language.code))
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
        analyticsManager.log(event: .signOut(lastScreen: "Settings"))
        logoutAlertSubject.accept(())
    }

    func copyUsernameToClipboard() {
        guard let username = storage.getName()?.withNameServiceDomain() else { return }
        clipboardManager.copyToClipboard(username)
        notificationsService.showInAppNotification(.done(L10n.copiedToClipboard))
    }

    func share(image: UIImage) {
        navigate(to: .share(item: image))
    }

    func saveImage(image: UIImage) {
        imageSaver.save(image: image) { [weak self] result in
            switch result {
            case .success:
                self?.notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
            case let .failure(error):
                switch error {
                case .noAccess:
                    self?.navigate(to: .accessToPhoto)
                case .restrictedRightNow:
                    break
                case let .unknown(error):
                    self?.notificationsService.showInAppNotification(.error(error))
                }
            }
        }
    }

    func logout() {
        analyticsManager.log(event: .signedOut)
        logoutResponder.logout()
    }
}
