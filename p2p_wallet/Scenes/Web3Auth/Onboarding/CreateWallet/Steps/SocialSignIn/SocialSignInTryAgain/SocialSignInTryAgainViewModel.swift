import AnalyticsManager
import Combine
import Foundation
import Onboarding
import Resolver

class SocialSignInTryAgainViewModel: NSObject {
    struct Input {
        let onTryAgain: PassthroughSubject<Void, Never> = .init()
        let onStartScreen: PassthroughSubject<Void, Never> = .init()
        let onError: PassthroughSubject<Error, Never> = .init()

        let isLoading: CurrentValueSubject<Bool, Never> = .init(false)
    }

    struct CoordinatorIO {
        let tryAgain: AnyPublisher<Void, Never>
        let startScreen: AnyPublisher<Void, Never>
    }

    @Injected var notificationService: NotificationService

    private(set) var input: Input = .init()
    private(set) var coordinator: CoordinatorIO
    var subscriptions = [AnyCancellable]()

    override init() {
        coordinator = .init(
            tryAgain: input.onTryAgain.eraseToAnyPublisher(),
            startScreen: input.onStartScreen.eraseToAnyPublisher()
        )

        super.init()

        input.onError.sink { [weak self] error in
            DispatchQueue.main.async {
                self?.notificationService.showDefaultErrorNotification()
//                self?.notificationService.showInAppNotification(.error(error))
            }
            DefaultLogManager.shared.log(event: error.readableDescription, logLevel: .error)

            Resolver.resolve(AnalyticsManager.self).log(title: "SocialSignInError", error: error)
        }.store(in: &subscriptions)
    }
}
