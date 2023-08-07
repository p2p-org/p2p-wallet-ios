import Combine
import Foundation
import Onboarding
import Reachability
import Resolver

class SocialSignInAccountHasBeenUsedViewModel: BaseViewModel, ObservableObject {
    struct Coordinator {
        let useAnotherAccount: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let switchToRestoreFlow: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let info: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let back: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
    }

    let coordinator: Coordinator = .init()

    @Published var emailAddress: String
    @Published var loading: Bool = false

    @Injected var notificationService: NotificationService
    @Injected var reachability: Reachability

    init(email: String) {
        emailAddress = email

        super.init()
    }

    func back() {
        coordinator.back.sendProcess()
    }

    func info() {
        coordinator.info.sendProcess()
    }

    func switchToRestore() {
        coordinator.switchToRestoreFlow.sendProcess()
    }

    func userAnotherAccount() {
        guard
            loading == false,
            reachability.check()
        else { return }

        loading = true
        coordinator.useAnotherAccount.sendProcess { [weak self] error in
            if let error = error {
                switch error {
                case is SocialServiceError:
                    break
                default:
                    self?.notificationService.showDefaultErrorNotification()
                }
            }

            self?.loading = false
        }
    }
}
