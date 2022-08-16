//
//  Settings.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import AnalyticsManager
import Combine
import Foundation
import LocalAuthentication
import RenVMSwift
import Resolver
import SolanaSwift

protocol ChangeLanguageResponder {
    func languageDidChange(to: LocalizedLanguage)
}

protocol ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: APIEndPoint)
}

protocol ChangeThemeResponder {
    func changeThemeTo(_ style: UIUserInterfaceStyle)
}

protocol LogoutResponder {
    func logout()
}

protocol SettingsViewModelType: ReserveNameHandler {
    var selectableLanguages: [(LocalizedLanguage, Bool)] { get }
    var navigatableScenePublisher: AnyPublisher<Settings.NavigatableScene?, Never> { get }
    var usernamePublisher: AnyPublisher<String?, Never> { get }
    var didBackupPublisher: AnyPublisher<Bool, Never> { get }
    var fiatPublisher: AnyPublisher<Fiat, Never> { get }
    var hideZeroBalancesPublisher: AnyPublisher<Bool, Never> { get }
    var logoutAlertPublisher: AnyPublisher<Void, Never> { get }
    var biometryTypePublisher: AnyPublisher<Settings.BiometryType, Never> { get }
    var isBiometryEnabledPublisher: AnyPublisher<Bool, Never> { get }
    var isBiometryAvailablePublisher: AnyPublisher<Bool, Never> { get }
    var appVersion: String { get }

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
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var storage: ICloudStorageType & AccountStorageType & NameStorageType & PincodeStorageType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var logoutResponder: LogoutResponder
        @Injected private var changeThemeResponder: ChangeThemeResponder
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

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        @Published private var username: String?
        @Published private var didBackup: Bool = false
        @Published private var fiat: Fiat = Defaults.fiat
        @Published private var endpoint: APIEndPoint = Defaults.apiEndPoint
        @Published private var securityMethods: [String] = []
        @Published private var theme: UIUserInterfaceStyle? = AppDelegate.shared.window?
            .overrideUserInterfaceStyle
        @Published private var hideZeroBalances: Bool = Defaults.hideZeroBalances
        @Published private var biometryType: BiometryType = .face
        @Published private var isBiometryEnabled: Bool = Defaults.isBiometryEnabled
        @Published private var isBiometryAvailable: Bool = false
        private let logoutAlertSubject = PassthroughSubject<Void, Never>()

        // MARK: - Initializer

        override init() {
            super.init()
            setUp()
            bind()
            username = storage.getName()
            didBackup = storage.didBackupUsingIcloud || Defaults.didBackupOffline
            securityMethods = getSecurityMethods()
        }

        // MARK: - Methods

        func setUp() {
            let context = LAContext()
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                isBiometryAvailable = true
            }

            switch context.biometryType {
            case .faceID:
                biometryType = .face
            case .touchID:
                biometryType = .touch
            default:
                biometryType = .none
            }
        }

        func bind() {
            disposables.append(Defaults.observe(\.forceCloseNameServiceBanner) { [weak self] _ in
                self?.username = self?.storage.getName()
            })

            storage
                .onValueChange
                .sink { [weak self] event in
                    if event.key == "getName", let name = event.value as? String {
                        self?.username = name
                    }
                }
                .store(in: &subscriptions)
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

    var navigatableScenePublisher: AnyPublisher<Settings.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var usernamePublisher: AnyPublisher<String?, Never> {
        $username.eraseToAnyPublisher()
    }

    var didBackupPublisher: AnyPublisher<Bool, Never> {
        $didBackup.eraseToAnyPublisher()
    }

    var fiatPublisher: AnyPublisher<Fiat, Never> {
        $fiat.eraseToAnyPublisher()
    }

    var hideZeroBalancesPublisher: AnyPublisher<Bool, Never> {
        $hideZeroBalances.eraseToAnyPublisher()
    }

    var logoutAlertPublisher: AnyPublisher<Void, Never> {
        logoutAlertSubject.eraseToAnyPublisher()
    }

    func getUserAddress() -> String? {
        storage.account?.publicKey.base58EncodedString
    }

    func getUsername() -> String? {
        storage.getName()
    }

    // MARK: - Actions

    func navigate(to scene: Settings.NavigatableScene) {
        navigatableScene = scene
    }

    func showOrReserveUsername() {
        if storage.getName() != nil {
            navigate(to: .username)
        } else {
            navigate(to: .reserveUsername)
        }
    }

    func setDidBackup(_ didBackup: Bool) {
        self.didBackup = didBackup
    }

    func setFiat(_ fiat: Fiat) {
        analyticsManager.log(event: .settingsСurrencySelected(сurrency: fiat.code))
        // set default fiat
        Defaults.fiat = fiat
        Task {
            await pricesService.clearCurrentPrices()
            try? await pricesService.fetchAllTokensPriceInWatchList()
        }

        // accept new value
        self.fiat = fiat
        notificationsService.showInAppNotification(.done(L10n.currencyChanged))
    }

    func setApiEndpoint(_ endpoint: APIEndPoint) {
        guard Defaults.apiEndPoint != endpoint else { return }
        self.endpoint = endpoint
        analyticsManager.log(event: .networkChanging(networkName: endpoint.address))
        Task {
            try await renVMService.expireCurrentSession()
            await MainActor.run {
                changeNetworkResponder.changeAPIEndpoint(to: endpoint)
            }
        }
    }

    var isBiometryEnabledPublisher: AnyPublisher<Bool, Never> { $isBiometryEnabled.eraseToAnyPublisher() }

    var isBiometryAvailablePublisher: AnyPublisher<Bool, Never> { $isBiometryAvailable.eraseToAnyPublisher() }

    var biometryTypePublisher: AnyPublisher<Settings.BiometryType, Never> { $biometryType.eraseToAnyPublisher() }

    var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }

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
                        self?.isBiometryEnabled = Defaults.isBiometryEnabled
                        self?.analyticsManager.log(event: .settingsSecuritySelected(faceId: Defaults.isBiometryEnabled))
                        self?.securityMethods = self?.getSecurityMethods() ?? []
                    } else {
                        if let authError = authenticationError as? LAError, authError.errorCode == kLAErrorUserCancel {
                            onError(nil)
                        } else {
                            onError(authenticationError)
                        }
                        // Setting actual value of biometry to the view
                        self?.isBiometryEnabled = self?.isBiometryEnabled ?? false
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
        self.theme = theme
        analyticsManager.log(event: .settingsAppearanceSelected(appearance: theme.name))
        changeThemeResponder.changeThemeTo(theme)
    }

    func setHideZeroBalances(_ hideZeroBalances: Bool) {
        Defaults.hideZeroBalances.toggle()
        analyticsManager.log(event: .settingsHideBalancesClick(hide: Defaults.hideZeroBalances))
        self.hideZeroBalances = hideZeroBalances
    }

    func showLogoutAlert() {
        analyticsManager.log(event: .signOut(lastScreen: "Settings"))
        logoutAlertSubject.send(())
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
