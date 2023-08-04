import AnalyticsManager
import Combine
import Resolver

/// ViewModel of `CryptoAccounts` scene
final class CryptoAccountsViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager
    private let interactor: CryptoAccountsInteractorProtocol
    private let navigation: PassthroughSubject<CryptoNavigation, Never>

    // MARK: - Properties

    @Published private(set) var scrollOnTheTop = true
    @Published private(set) var hideZeroBalance: Bool = Defaults.hideZeroBalances

    @Published var transferAccounts: [any RenderableAccount] = []
    @Published var primaryAccounts: [any RenderableAccount] = []
    @Published var hiddenAccounts: [any RenderableAccount] = []

    // MARK: - Initialization

    init(
        interactor: CryptoAccountsInteractorProtocol,
        navigation: PassthroughSubject<CryptoNavigation, Never>
    ) {
        self.interactor = interactor
        self.navigation = navigation

        super.init()
        
        bindToInteractor()
    }

    // MARK: - Binding
    
    private func bindToInteractor() {
        interactor.transferAccountsPublisher
            .assignWeak(to: \.transferAccounts, on: self)
            .store(in: &subscriptions)
        interactor.primaryAccountsPublisher
            .assignWeak(to: \.primaryAccounts, on: self)
            .store(in: &subscriptions)
        interactor.hiddenAccountsPublisher
            .assignWeak(to: \.hiddenAccounts, on: self)
            .store(in: &subscriptions)
        interactor.zeroBalanceTogglePublisher
            .assignWeak(to: \.hideZeroBalance, on: self)
            .store(in: &subscriptions)
    }

    // MARK: - Actions

    func refresh() async {
        await interactor.refreshServices()
    }

    func scrollToTop() {
        scrollOnTheTop = true
    }

    func invoke(for account: any RenderableAccount, event: Event) {
        switch account {
        case let renderableAccount as RenderableSolanaAccount:
            switch event {
            case .tap:
                analyticsManager.log(event: .cryptoTokenClick(tokenName: renderableAccount.account.token.symbol))
                navigation.send(.solanaAccount(renderableAccount.account))
            case .visibleToggle:
                interactor.updateFavorites(renderableAccount: renderableAccount)
            default:
                break
            }

        case let renderableAccount as RenderableEthereumAccount:
            switch event {
            case .tap:
                analyticsManager.log(event: .cryptoTokenClick(tokenName: renderableAccount.account.token.symbol))
            case .extraButtonTap:
                analyticsManager.log(event: .cryptoClaimTransferredClick)
                navigation.send(.claim(renderableAccount.account, renderableAccount.userAction))
            default:
                break
            }

        default:
            break
        }
    }
}

extension CryptoAccountsViewModel {
    enum Event {
        case tap
        case visibleToggle
        case extraButtonTap
    }
}
