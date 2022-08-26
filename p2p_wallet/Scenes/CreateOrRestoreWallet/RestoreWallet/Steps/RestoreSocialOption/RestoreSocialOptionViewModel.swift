import Combine
import Onboarding
import Resolver
import SwiftUI

final class RestoreSocialOptionViewModel: BaseViewModel {
    @Injected var notificationService: NotificationService

    @Published var isLoading: SocialProvider?

    let optionDidTap = PassthroughSubject<SocialProvider, Never>()
    let optionChosen = PassthroughSubject<ReactiveProcess<SocialProvider>, Never>()

    override init() {
        super.init()

        optionDidTap.sink { [weak self] provider in
            guard let self = self else { return }
            self.isLoading = provider

            self.notificationService.hideToasts()
            let process = ReactiveProcess<SocialProvider>(data: provider) { error in
                if let error = error {
                    switch error {
                    case is SocialServiceError:
                        break
                    default:
                        self.notificationService.showDefaultErrorNotification()
                    }
                }
                self.isLoading = nil
            }

            self.optionChosen.send(process)

        }.store(in: &subscriptions)
    }
}
