import Combine

class PinCodeViewModel: ObservableObject {
    @Published var currentPincode: String?
    @Published var attemptsCount: Int = 0
    
    let correctPincode: String?
    let maxAttemptsCount: Int?
    let stackViewSpacing: CGFloat = 10
    let pincodeLength: Int
    let resetingDelayInSeconds: Int?
    
    private var isPresentingError = false
    
    var onSuccess = PassthroughSubject<Void, Never>()
    var onFailed = PassthroughSubject<Void, Never>()
    var onFailedAndExceededMaxAttempts = PassthroughSubject<Void, Never>()
    
    init(correctPincode: String? = nil, maxAttemptsCount: Int? = nil, pincodeLength: Int = 6, resetingDelayInSeconds: Int? = nil) {
        self.correctPincode = correctPincode
        self.maxAttemptsCount = maxAttemptsCount
        self.pincodeLength = pincodeLength
        self.resetingDelayInSeconds = resetingDelayInSeconds
    }
    
    func reset() {
        attemptsCount = 0
        currentPincode = nil
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
                
                if attemptsCount >= maxAttemptsCount {
                    pincodeFailed(exceededMaxAttempts: true)
                } else {
                    pincodeFailed(exceededMaxAttempts: false)
                }
            } else {
                pincodeFailed(exceededMaxAttempts: false)
            }
        }
    }
    
    private func pincodeSuccess() {
        vibrate()
        attemptsCount = 0
        onSuccess.send()
    }
    
    private func pincodeFailed(exceededMaxAttempts: Bool) {
        vibrate()
        // Emit the corresponding event through the publishers
        if exceededMaxAttempts {
            onFailedAndExceededMaxAttempts.send()
        } else {
            onFailed.send()
            clearErrorWithDelay()
        }
    }
    
    private func clearErrorWithDelay() {
        guard let resetingDelayInSeconds = resetingDelayInSeconds else {
            return
        }
        
        isPresentingError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(resetingDelayInSeconds)) { [weak self] in
            guard let self = self, self.isPresentingError else { return }
            self.currentPincode = nil
        }
    }
    
    private func vibrate() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
