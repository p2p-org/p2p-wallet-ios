import Combine
import LocalAuthentication
import Resolver

class PinCodeViewModel: BaseViewModel, ObservableObject {

    // MARK: - Dependencies
    
    @Injected private var biometricsAuthProvider: BiometricsAuthProvider
    
    // MARK: - Published Properties
    
    @Published var isBiometryAvailable: Bool = false
    @Published var currentPincode: String?
    @Published var attemptsCount: Int = 0
    @Published var isPresentingError = false
    @Published var isLocked = false

    // MARK: - Private properties
    
    /// Status of biometry authentication.
    private var bioAuthStatus: LABiometryType {
        biometricsAuthProvider.availabilityStatus
    }

    // MARK: - Constants
    
    /// The title to be displayed in the pincode view.
    let title: String
    
    /// Indicates whether the "Forgot Pin" option should be shown.
    let showForgetPin: Bool

    let correctPincode: String?
    let maxAttemptsCount: Int?
    let stackViewSpacing: CGFloat = 10
    let pincodeLength: Int
    let resetingDelayInSeconds: Int?
    
    // MARK: - Subjects
    
    var onSuccess = PassthroughSubject<Void, Never>()
    var onFailed = PassthroughSubject<Void, Never>()
    var onFailedAndExceededMaxAttempts = PassthroughSubject<Void, Never>()
    
    // MARK: - Initialization
    
    init(
        title: String,
        showForgetPin: Bool,
        isBiometryEnabled: Bool,
        correctPincode: String? = nil,
        maxAttemptsCount: Int? = nil,
        pincodeLength: Int = 6,
        resetingDelayInSeconds: Int?
    ) {
        self.title = title
        self.showForgetPin = showForgetPin
        self.correctPincode = correctPincode
        self.maxAttemptsCount = maxAttemptsCount
        self.pincodeLength = pincodeLength
        self.resetingDelayInSeconds = resetingDelayInSeconds
        
        super.init()
        
        // check if biometry available
        isBiometryAvailable = isBiometryEnabled && (bioAuthStatus == .faceID || bioAuthStatus == .touchID)
        
        // start authenticating via biometry immediately
        self.validateBiometry()
    }
    
    // MARK: - Public Methods
    
    func reset() {
        attemptsCount = 0
        currentPincode = nil
        isPresentingError = false
    }
    
    func add(digit: Int) {
        guard digit >= 0, digit < 10 else { return }
        
        vibrate()
        isPresentingError = false
        
        let newValue = (currentPincode ?? "") + String(digit)
        let numberOfDigits = newValue.count
        
        guard numberOfDigits <= pincodeLength else {
            currentPincode = String(digit)
            return
        }
        
        currentPincode = newValue
    }
    
    func backspace() {
        guard let currentPincode = currentPincode, currentPincode.count > 1 else {
            currentPincode = nil
            return
        }
        
        vibrate()
        self.currentPincode = String(currentPincode.dropLast())
    }
    
    func validateBiometry() {
        guard isBiometryAvailable else { return }
        biometricsAuthProvider.authenticate(
            authenticationPrompt: L10n.enterPINCode, completion: { [weak self] success, _ in
                if success {
//                    self?.pincodeService.resetAttempts()
//                    self.authenticationHandler.authenticate(presentationStyle: nil)
//                    self.openMain.send((pin, success))
                    self?.pincodeSuccess()
                }
            }
        )
    }
    
    func validatePincode() {
        guard let currentPincode = currentPincode, currentPincode.count <= pincodeLength else {
            return
        }
        
        let numberOfDigits = currentPincode.count
        
        if numberOfDigits == pincodeLength {
            guard let correctPincode = correctPincode else {
                pincodeSuccess()
                return
            }
            
            if currentPincode == correctPincode {
                pincodeSuccess()
            } else if let maxAttemptsCount = maxAttemptsCount {
                attemptsCount += 1
                pincodeFailed(exceededMaxAttempts: attemptsCount >= maxAttemptsCount)
            } else {
                pincodeFailed(exceededMaxAttempts: false)
            }
        }
    }

    // MARK: - Private Methods
    
    private func pincodeSuccess() {
        vibrate()
        attemptsCount = 0
        onSuccess.send()
    }
    
    private func pincodeFailed(exceededMaxAttempts: Bool) {
        vibrate()
        isPresentingError = true
        // Emit the corresponding event through the publishers
        if exceededMaxAttempts {
            isLocked = true
            onFailedAndExceededMaxAttempts.send()
        } else {
            onFailed.send()
            clearErrorWithDelay()
        }
    }
    
    private func clearErrorWithDelay() {
        if let resetingDelayInSeconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(resetingDelayInSeconds)) { [weak self] in
                self?.isPresentingError = false
                self?.currentPincode = nil
            }
        }
    }
    
    private func vibrate() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
