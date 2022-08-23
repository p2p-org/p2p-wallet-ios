import Combine
import Onboarding
import SwiftUI

final class RestoreSocialOptionViewModel: BaseViewModel {
    @Published var isLoading: SocialProvider?

    let optionDidTap = PassthroughSubject<SocialProvider, Never>()
    let optionChosen = PassthroughSubject<ReactiveProcess<SocialProvider>, Never>()

    override init() {
        super.init()

        optionDidTap.sink { [weak self] provider in
            guard let self = self else { return }
            self.isLoading = provider

            let process = ReactiveProcess<SocialProvider>(data: provider) { error in
                if let error = error {}
                self.isLoading = nil
            }

            self.optionChosen.send(process)

        }.store(in: &subscriptions)
    }
}
