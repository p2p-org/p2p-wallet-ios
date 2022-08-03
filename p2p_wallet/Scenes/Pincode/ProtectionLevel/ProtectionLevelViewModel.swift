import Combine
import LocalAuthentication
import Resolver
import UIKit

extension ProtectionLevelViewModel {
    enum NavigatableScene {
        case createPincode
        case main
    }
}

final class ProtectionLevelViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var biometricsAuthProvider: BiometricsAuthProvider

    // MARK: - Properties

    @Published var data: OnboardingContentData
    @Published var localAuthTitle = ""
    @Published var localAuthImage: UIImage?
    @Published var navigatableScene: NavigatableScene?

    let useLocalAuthDidTap = PassthroughSubject<Void, Never>()
    let setUpPinDidTap = PassthroughSubject<Void, Never>()

    private var bioAuthStatus: LABiometryType { biometricsAuthProvider.availabilityStatus }

    override init() {
        data = OnboardingContentData(
            image: .lockMagic,
            title: L10n.addALevelOfProtection,
            subtitle: L10n.forLoggingInAndVerifyingTransactions
        )
        super.init()

        localAuthTitle = L10n.use(bioAuthStatus.stringValue)
        localAuthImage = bioAuthStatus.icon

        setUpPinDidTap.sink { [weak self] _ in
            self?.navigatableScene = .createPincode
        }.store(in: &subscriptions)

        useLocalAuthDidTap.sink { [weak self] _ in
            guard let self = self else { return }
            let prompt = L10n.insteadOfAPINCodeYouCanAccessTheAppUsing(self.bioAuthStatus.stringValue)
            self.biometricsAuthProvider.authenticate(authenticationPrompt: prompt, completion: { success in
                if success {
                    self.navigatableScene = .main
                } else {
                    // TODO: handle error
                }
            })
        }.store(in: &subscriptions)
    }
}
