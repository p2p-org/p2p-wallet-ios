import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Sell
import Send
import SolanaSwift
import UIKit
import Wormhole

/// ViewModel of `Crypto` scene
final class CryptoViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var authenticationHandler: AuthenticationHandlerType
    @Injected private var solanaAccountsService: SolanaAccountsService
    @Injected private var ethereumAccountsService: EthereumAccountsService
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var solanaTracker: SolanaTracker
    @Injected private var notificationsService: NotificationService
    @Injected private var accountStorage: SolanaAccountStorage
    @Injected private var nameStorage: NameStorageType
    @Injected private var sellDataService: any SellDataService
    @Injected private var createNameService: CreateNameService
    @Injected private var applicationUpdateManager: ApplicationUpdateManager
    @Injected private var referralService: ReferralProgramService

    let navigation: PassthroughSubject<CryptoNavigation, Never>
    let openReferralProgramDetails = PassthroughSubject<Void, Never>()
    let shareReferralLink = PassthroughSubject<Void, Never>()

    // MARK: - Properties

    @Published private(set) var displayReferralBanner: Bool
    @Published var state = State.pending
    @Published var address = ""

    @Published var updateAlert: Bool = false
    @Published var newVersion: Version?

    // MARK: - Initializers

    init(navigation: PassthroughSubject<CryptoNavigation, Never>) {
        self.navigation = navigation
        displayReferralBanner = available(.referralProgramEnabled)

        super.init()

        // bind
        bind()

        // reload
        Task { await reload() }
    }

    // MARK: - Methods

    private func reload() async {
        await CryptoAccountsSynchronizationService().refresh()
    }

    func userIsAwareAboutUpdate() {
        guard let version = newVersion else { return }
        Task { await applicationUpdateManager.awareUser(version: version) }
    }

    func openAppstore() {
        UIApplication.shared.open(
            URL(string: "itms-apps://itunes.apple.com/app/id1605603333")!,
            options: [:],
            completionHandler: nil
        )
    }

    func viewAppeared() {
        if available(.solanaNegativeStatus) {
            solanaTracker.startTracking()
        }
        updateAddressIfNeeded()
        analyticsManager.log(event: .cryptoScreenOpened)
        displayReferralBanner = available(.referralProgramEnabled)
    }

    func copyToClipboard() {
        clipboardManager
            .copyToClipboard(nameStorage.getName() ?? solanaAccountsService.state.value.nativeWallet?.address ?? "")
        let text: String
        if nameStorage.getName() != nil {
            text = L10n.usernameCopiedToClipboard
        } else {
            text = L10n.addressCopiedToClipboard
        }
        notificationsService.showToast(title: "", text: text, haptic: true)
        analyticsManager.log(event: .mainScreenAddressClick)
    }

    func updateAddressIfNeeded() {
        if let name = nameStorage.getName(), !name.isEmpty {
            address = name
        } else if let address = accountStorage.account?.publicKey.base58EncodedString.shortAddress {
            self.address = address
        }
    }
}

private extension CryptoViewModel {
    func bind() {
        // Monitor solana network
        if available(.solanaNegativeStatus) {
            solanaTracker.unstableSolana
                .sink { [weak self] in
                    self?.notificationsService.showToast(
                        title: "😴",
                        text: L10n.solanaHasSomeProblems,
                        withAutoHidden: false
                    )
                }
                .store(in: &subscriptions)
        }

        // Monitor user action
        let userActionService: UserActionService = Resolver.resolve()
        userActionService
            .actions
            .withPrevious()
            .sink { [weak self] prev, next in
                for updatedUserAction in next {
                    if let oldUserAction = prev?.first(where: { $0.id == updatedUserAction.id }) {
                        // Status if different
                        guard oldUserAction.status != updatedUserAction.status else { continue }

                        // Claiming
                        if case .error = updatedUserAction.status {
                            if updatedUserAction is WormholeClaimUserAction {
                                self?.notificationsService
                                    .showInAppNotification(.error(L10n.ThereWasAProblemWithClaiming.pleaseTryAgain))
                            }
                        }

                        // Sending
                        if case .error = updatedUserAction.status {
                            switch updatedUserAction {
                            case is WormholeClaimUserAction:
                                self?.notificationsService
                                    .showInAppNotification(.error(L10n.ThereWasAProblemWithClaiming.pleaseTryAgain))
                            case is WormholeSendUserAction:
                                self?.notificationsService
                                    .showInAppNotification(.error(L10n.ThereWasAProblemWithSending.pleaseTryAgain))
                            default:
                                break
                            }
                        }
                    }
                }
            }
            .store(in: &subscriptions)

        // state, address, error, log

        Publishers
            .CombineLatest(solanaAccountsService.statePublisher, ethereumAccountsService.statePublisher)
            .receive(on: RunLoop.main)
            .sink { [weak self] solanaState, ethereumState in
                guard let self else { return }

                let solanaTotalBalance = solanaState.value.reduce(into: 0) { partialResult, account in
                    partialResult = partialResult + account.amountInFiatDouble
                }

                // TODO: Bad place
                self.updateAddressIfNeeded()

                let hasAnyTokenWithPositiveBalance =
                    solanaState.value.contains(where: { $0.lamports > 0 }) ||
                    ethereumState.value.contains(where: { $0.balance > 0 })

                // Merge two status
                let mergedStatus = AsynValueStatus.combine(lhs: solanaState.status, rhs: ethereumState.status)

                switch mergedStatus {
                case .initializing:
                    self.state = .pending
                default:
                    self.state = hasAnyTokenWithPositiveBalance ? .accounts : .empty

                    // log
                    self.analyticsManager.log(parameter: .userHasPositiveBalance(solanaTotalBalance > 0))
                    self.analyticsManager.log(parameter: .userAggregateBalance(solanaTotalBalance))
                }
            }
            .store(in: &subscriptions)

        // update name when needed
        createNameService.createNameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSuccess in
                guard isSuccess else { return }
                self?.updateAddressIfNeeded()
            }
            .store(in: &subscriptions)

        // Update
        authenticationHandler.authenticationStatusPublisher
            .filter { $0 == nil }
            .delay(for: 3, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    let result = await self.applicationUpdateManager.isUpdateAvailable()
                    switch result {
                    case .noUpdate:
                        return
                    case let .updateAvailable(version):
                        if await self.applicationUpdateManager.isUserAwareAboutUpdate(version: version) {
                            return
                        } else {
                            await MainActor.run {
                                self.updateAlert = true
                                self.newVersion = version
                            }
                        }
                    }
                }
            }.store(in: &subscriptions)

        openReferralProgramDetails
            .map { CryptoNavigation.referral }
            .sink { [weak self] navigation in
                self?.navigation.send(navigation)
            }
            .store(in: &subscriptions)

        shareReferralLink
            .compactMap { [weak self] in
                guard let self else { return nil }
                return CryptoNavigation.shareReferral(self.referralService.shareLink)
            }
            .sink { [weak self] navigation in
                self?.navigation.send(navigation)
            }
            .store(in: &subscriptions)

        // solana account vs pnl, get for the first time
        if available(.pnlEnabled) {
            solanaAccountsService.statePublisher
                .receive(on: RunLoop.main)
                .filter { $0.status == .ready }
                .prefix(1)
                .sink { _ in
                    Task {
                        await Resolver.resolve(PnLRepository.self).reload()
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

// MARK: - Nested Types

extension CryptoViewModel {
    enum State {
        case pending
        case empty
        case accounts
    }
}
