import Combine
import Onboarding
import Resolver

final class SocialSignInWaitViewModel: BaseViewModel, ObservableObject {

    enum State {
        case initial
        case creatingWallet
        case securingKey
        case almostDone
    }

    @Injected private var notificationService: NotificationService

    @Published var title: String = ""
    @Published var subtitle: String = L10n.pleaseWaitItWonTTakeLong
    @Published var isProgressVisible: Bool = false
    @Published private var state: State = .initial

    let initiated: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
    let appeared: PassthroughSubject<Void, Never> = .init()
    let back: PassthroughSubject<Void, Never> = .init()

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    private var isProcessSent: Bool = false

    override init() {
        super.init()

        $state
            .sink { [weak self] currentState in
                guard let self = self else { return }
                switch currentState {
                case .initial:
                    self.title = "\(L10n.creatingWallet)..."
                    self.isProgressVisible = false
                case .creatingWallet:
                    self.title = L10n.creatingWallet
                    self.isProgressVisible = true
                case .securingKey:
                    self.title = L10n.securingKey
                case .almostDone:
                    self.title = "\(L10n.almostDone)!"
                }
            }
            .store(in: &subscriptions)

        timer
            .sink { [weak self] _ in
                guard let self = self else { return }
                switch self.state {
                case .initial:
                    self.state = .creatingWallet
                case .creatingWallet:
                    self.state = .securingKey
                case .securingKey:
                    self.state = .almostDone
                case .almostDone:
                    self.timer.upstream.connect().cancel()
                }
            }
            .store(in: &subscriptions)

        appeared
            .sink { [weak self] _ in
                guard let self = self, !self.isProcessSent else { return }
                self.isProcessSent = true
                self.initiated.sendProcess { error in
                    guard error != nil else { return }
                    self.notificationService.showDefaultErrorNotification()
                    self.back.send()
                }
            }
            .store(in: &subscriptions)
    }
}
