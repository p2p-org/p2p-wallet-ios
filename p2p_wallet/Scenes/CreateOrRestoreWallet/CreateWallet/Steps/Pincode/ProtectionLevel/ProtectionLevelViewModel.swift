import Combine
import LocalAuthentication
import Resolver
import UIKit

final class ProtectionLevelViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var biometricsAuthProvider: BiometricsAuthProvider

    // MARK: - Properties

    @Published var data: OnboardingContentData
    @Published var localAuthTitle = ""
    @Published var localAuthImage: UIImage?

    let useLocalAuthDidTap = PassthroughSubject<Void, Never>()
    let setUpPinDidTap = PassthroughSubject<Void, Never>()
    let authenticatedSuccessfully = PassthroughSubject<Void, Never>()
    let viewAppeared = PassthroughSubject<Void, Never>()

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

        useLocalAuthDidTap.sink { [weak self] _ in
            guard let self = self else { return }
            let prompt = L10n.insteadOfAPINCodeYouCanAccessTheAppUsing(self.bioAuthStatus.stringValue)
            self.biometricsAuthProvider.authenticate(authenticationPrompt: prompt, completion: { success, error in
                if success {
                    self.authenticatedSuccessfully.send()
                } else if let error = error, error.code == kLAErrorUserCancel {
                    self.setUpPinDidTap.send()
                } else {
                    // System will handle is itself
                }
            })
        }.store(in: &subscriptions)
    }
}
