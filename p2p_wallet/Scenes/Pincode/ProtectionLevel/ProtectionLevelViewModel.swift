import Combine
import LocalAuthentication
import Resolver

extension ProtectionLevelViewModel {
    enum NavigatableScene {
        case pin
    }
}

final class ProtectionLevelViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var biometricsAuthProvider: BiometricsAuthenticationProvider

    // MARK: - Properties

    @Published var data: OnboardingContentData
    @Published var bioAuthButtonTitle: String = ""
    @Published var navigatableScene: NavigatableScene?

    let useFaceIdDidTap = PassthroughSubject<Void, Never>()
    let setUpPinDidTap = PassthroughSubject<Void, Never>()

    private var bioAuthStatus: LABiometryType {
        biometricsAuthProvider.availabilityStatus
    }

    override init() {
        data = OnboardingContentData(
            image: .lockMagic,
            title: L10n.addALevelOfProtection,
            subtitle: L10n.forLoggingInAndVerifyingTransactions
        )
        super.init()

        setUpPinDidTap.sink { [weak self] _ in
            self?.navigatableScene = .pin
        }.store(in: &subscriptions)

        useFaceIdDidTap.sink { [weak self] _ in
            guard let self = self else { return }
            let prompt = L10n
                .insteadOfAPINCodeYouCanAccessTheAppUsing(self.bioAuthStatus.stringValue)
            self.biometricsAuthProvider.authenticate(authenticationPrompt: prompt, completion: { success in
                debugPrint(success)
            })
        }.store(in: &subscriptions)

        bioAuthButtonTitle = L10n.use(bioAuthStatus.stringValue)
    }
}
