import Combine
import CountriesAPI
import Foundation
import PhoneNumberKit
import Resolver

#if DEBUG
    let EnterSMSCodeCountdown = 5
#else
    let EnterSMSCodeCountdown = 60
#endif

final class EnterSMSCodeViewModel: BaseViewModel {
    @Injected var smsService: SMSService

    // MARK: -

    private var cancellable = Set<AnyCancellable>()
    private var countdown = EnterSMSCodeCountdown
    private static let codeLength = 6

    // MARK: -

    private var rawCode: String = "" {
        didSet {
            isButtonEnabled = rawCode.count == Self.codeLength
        }
    }

    @Published public var phone: String
    @Published public var code: String = ""
    /// Input error field
    @Published public var codeError: String?
    /// Toaster error
    @Published public var error: String?
    @Published public var isLoading: Bool = false
    @Published public var resendEnabled: Bool = false
    @Published public var resendText: String = ""
    @Published public var isButtonEnabled: Bool = false

    func buttonTaped() {
        setLoading(true)
        Task.detached { [weak self] in
            guard let self = self else { return }

            await self.showCodeError(error: nil)

            do {
                let result = try await self.smsService.confirm(phone: self.phone, code: self.rawCode)
                if !result {
                    await self.showCodeError(error: EnterSMSCodeViewModelError.incorrectCode)
                } else {
                    await self.codeConfirmed(code: self.rawCode)
                }
            } catch let err {
                await self.showError(error: err)
            }
            await self.setLoading(false)
            await self.updateResendEnabled()
        }
    }

    func resendButtonTapped() {
        countdown = EnterSMSCodeCountdown
        timer?.invalidate()
        startTimer()
        setResendCountdown()
        Task {
            do {
                try await self.smsService.sendConfirmationCode(phone: phone)
            } catch let err {
                self.showCodeError(error: err)
            }
        }
    }

    func backTapped() {}

    func infoTapped() {}

    // MARK: -

    var coordinatorIO: CoordinatorIO = .init()

    private var timer: Timer?

    init(phone: String) {
        self.phone = phone

        super.init()

        bind()

        Task {
            do {
                try await smsService.sendConfirmationCode(phone: phone)
            } catch let err {
                self.error = err.readableDescription
            }
        }

        startTimer()
        RunLoop.current.add(timer!, forMode: .common)
    }

    func bind() {
        $code.removeDuplicates()
            .debounce(for: 0.0, scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] aCode in
                self?.showCodeError(error: nil)
                self?.rawCode = Self.prepareRawCode(code: aCode)
            })
            .map { Self.format(code: $0) }
            .assign(to: \.code, on: self)
            .store(in: &cancellable)
    }

    private func codeConfirmed(code: String) {
        coordinatorIO.isConfirmed.send(code)
    }

    @MainActor
    private func showCodeError(error: Error?) {
        var errorText = error?.readableDescription
        if let error = error as? EnterSMSCodeViewModelError {
            switch error {
            case .incorrectCode:
                errorText = "Incorrect SMS code 😬"
            }
        }
        codeError = errorText
    }

    @MainActor
    private func showError(error: Error?) {
        var errorText = error?.readableDescription
        if let error = error as? SMSServiceError {
            switch error {
            case .wait10Min:
                errorText = "Please wait 10 min and will ask for new OTP"
            case .invalidSignature:
                errorText = "Not valid signature"
            case .parseError:
                errorText = "Parse Error"
            case .invalidRequest:
                errorText = "Invalid Request"
            case .methodNotFOund:
                errorText = "Method not found"
            case .invalidParams:
                errorText = "Invalid params"
            case .internalError:
                errorText = "Internal Error"
            case .everytingIsBroken:
                errorText = "Everything is broken"
            case .retry:
                errorText = "Please retry operation"
            case .changePhone:
                errorText = "SMS will not be delivered. Please change phone number"
            case .alreadyConfirmed:
                errorText = "This phone has already been confirmed. Change phone number"
            case .callNotPermit:
                errorText = "Call not permit. Use sms. May be it helps"
            case .pubkeyExists:
                errorText = "Pubkey solana already exists"
            case .pubkeyAndPhoneExists:
                errorText = "Pubkey solana and phone number already exists"
            case .invalidValue:
                errorText = "Invalid value of OTP. Please try again to input correct value of OTP"
            }
        }
        self.error = errorText

        if let errorText = errorText {
            DefaultLogManager.shared.log(event: "Enter SMS: \(errorText)", logLevel: .error, shouldLogEvent: { true })
        }
    }

    @MainActor
    private func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
        resendEnabled = !isLoading
    }

    // MARK: -

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.countdown -= 1
            self?.setResendCountdown()

            if self?.countdown == 0 {
                self?.timer?.invalidate()
                self?.setResendCountdown()
                return
            }
        }
    }

    private func setResendCountdown() {
        let secs = countdown <= 0 ? "" : " \(countdown) sec"
        resendText = " Tap to resend\(secs)"
        updateResendEnabled()
    }

    private func updateResendEnabled() {
        resendEnabled = countdown <= 0 && !isLoading
    }

    // MARK: -

    static func format(code: String) -> String {
        Self.prepareRawCode(code: code)
            .prefix(Self.codeLength)
            .asString()
            .separate(every: 3, with: " ")
    }

    static func prepareRawCode(code: String) -> String {
        code.replacingOccurrences(of: " ", with: "")
    }
}

extension String {
    func separate(every: Int, with separator: String) -> String {
        String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0 ..< min($0 + every, Array(self).count)])
        }.joined(separator: separator))
    }
}

extension Substring {
    func asString() -> String {
        String(self)
    }
}

extension EnterSMSCodeViewModel {
    struct CoordinatorIO {
        var isConfirmed: PassthroughSubject<String, Never> = .init()
        var showInfo: PassthroughSubject<Void, Never> = .init()
        var goBack: PassthroughSubject<Void, Never> = .init()
    }

    enum EnterSMSCodeViewModelError: Error {
        case incorrectCode
    }
}
