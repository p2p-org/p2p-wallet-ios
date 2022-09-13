import AnalyticsManager
import Combine
import Foundation
import Resolver
import SolanaSwift

protocol NewAccountRestorationHandler {
    func derivablePathDidSelect(path: DerivablePath, phrases: [String]) async throws
}

protocol NewDrivableAccountsViewModelType {
    var loadingPublisher: AnyPublisher<Bool, Never> { get }
    var accountsListViewModel: NewDerivableAccountsListViewModelType { get }
    var navigatableScenePublisher: AnyPublisher<NewDerivableAccounts.NavigatableScene?, Never> { get }
    var selectedDerivablePathPublisher: AnyPublisher<DerivablePath, Never> { get }

    func getCurrentSelectedDerivablePath() -> DerivablePath
    func chooseDerivationPath()
    func selectDerivationPath(_ path: DerivablePath)
    func restoreAccount()
    func onBack()
}

extension NewDerivableAccounts {
    class ViewModel: BaseViewModel, NewAccountRestorationHandler {
        // MARK: - Dependencies

        @Injected var analyticsManager: AnalyticsManager
        @Injected var notificationsService: NotificationService
        @Injected var appEventHandler: AppEventHandlerType
        @Injected private var iCloudStorage: ICloudStorageType

        // MARK: - Properties

        private let phrases: [String]
        private var derivablePath: DerivablePath?
        let accountsListViewModel: NewDerivableAccountsListViewModelType

        // MARK: - Subjects

        @Published private var navigatableScene: NavigatableScene?
        @Published private var selectedDerivablePath = DerivablePath.default
        @Published var loading = false
        @Published var error: String?

        // MARK: - Initializer

        init(phrases: [String]) {
            self.phrases = phrases
            accountsListViewModel = ListViewModel(phrases: phrases)
        }

        struct CoordinatorIO {
            var didSucceed = PassthroughSubject<([String], DerivablePath), Never>()
            var back = PassthroughSubject<Void, Never>()
        }

        let coordinatorIO = CoordinatorIO()
    }
}

extension NewDerivableAccounts.ViewModel: NewDrivableAccountsViewModelType {
    var loadingPublisher: AnyPublisher<Bool, Never> {
        $loading.eraseToAnyPublisher()
    }

    var navigatableScenePublisher: AnyPublisher<NewDerivableAccounts.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var selectedDerivablePathPublisher: AnyPublisher<DerivablePath, Never> {
        $selectedDerivablePath.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func getCurrentSelectedDerivablePath() -> DerivablePath {
        selectedDerivablePath
    }

    func chooseDerivationPath() {
        navigatableScene = .selectDerivationPath
    }

    func selectDerivationPath(_ path: DerivablePath) {
        selectedDerivablePath = path
    }

    func onBack() {
        coordinatorIO.back.send()
    }

    func restoreAccount() {
        // cancel any requests
        accountsListViewModel.cancelRequest()

        loading = true
        // send to handler
        Task {
            do {
                try await self.derivablePathDidSelect(path: selectedDerivablePath, phrases: phrases)
            } catch {
                self.notificationsService.showToast(title: nil, text: error.readableDescription)
            }
            self.loading = false
        }
    }

    func derivablePathDidSelect(path: DerivablePath, phrases: [String]) async throws {
        analyticsManager.log(event: AmplitudeEvent.recoveryRestoreClick)
        // save to icloud

        coordinatorIO.didSucceed.send((phrases, path))
    }

    // MARK: -

    // Commented it for now, but can use this method insted of delegation stuff
    /*
        func derivablePathDidSelect(_ derivablePath: DerivablePath, phrases: [String]) async throws {
            analyticsManager.log(event: .recoveryRestoreClick)
            // save to icloud
            saveToICloud(name: nil, phrase: phrases, derivablePath: derivablePath)

            try await saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: nil, deviceShare: nil)
        }

        @MainActor
        private func saveToICloud(name: String?, phrase: [String], derivablePath: DerivablePath) {
            _ = iCloudStorage.saveToICloud(
                account: .init(
                    name: name,
                    phrase: phrase.joined(separator: " "),
                    derivablePath: derivablePath
                )
            )
            notificationsService.showInAppNotification(.done(L10n.savedToICloud))
        }

        private func saveAccountToStorage(
            phrases: [String],
            derivablePath: DerivablePath,
            name: String?,
            deviceShare: String?
        ) async throws {
            try storage.save(phrases: phrases)
            try storage.save(derivableType: derivablePath.type)
            try storage.save(walletIndex: derivablePath.walletIndex)

            try await storage.reloadSolanaAccount()

            if let name = name {
                storage.save(name: name)
            }

            if let deviceShare = deviceShare {
                try storage.save(deviceShare: deviceShare)
            }
        }
     */
}
