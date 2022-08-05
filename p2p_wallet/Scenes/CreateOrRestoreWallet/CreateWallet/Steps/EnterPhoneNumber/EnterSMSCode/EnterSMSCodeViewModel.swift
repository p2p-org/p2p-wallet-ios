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

final class EnterSMSCodeViewModel: BaseOTPViewModel {
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
    @Published public var isLoading: Bool = false
    @Published public var resendEnabled: Bool = false
    @Published public var resendText: String = ""
    @Published public var isButtonEnabled: Bool = false

    func buttonTaped() {
        guard !isLoading else { return }
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
                errorText = L10n.incorrectSMSCode😬
            }
        }
        codeError = errorText
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
