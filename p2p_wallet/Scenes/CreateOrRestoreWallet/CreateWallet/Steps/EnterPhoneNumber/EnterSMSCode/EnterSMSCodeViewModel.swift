import Combine
import CountriesAPI
import Foundation
import Onboarding
import PhoneNumberKit
import Reachability
import Resolver
import SwiftyUserDefaults

let EnterSMSCodeCountdownLegs = [30, 40, 60, 90, 120]

final class EnterSMSCodeViewModel: BaseOTPViewModel {
    // MARK: -

    private let countdownSteps = EnterSMSCodeCountdownLegs
    private static var phoneSteps = [String: Int]()

    private var cancellable = Set<AnyCancellable>()
    private var countdown: Int
    private static let codeLength = 6

    // MARK: -

    @Injected private var reachability: Reachability

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
        guard
            !isLoading,
            reachability.check()
        else { return }
        coordinatorIO.onConfirm.send(rawCode)
    }

    func resendButtonTapped() {
        guard
            !isLoading,
            reachability.check()
        else { return }
        coordinatorIO.onResend.send()

        // Setup timer
        countdown = countdownSteps[Self.phoneSteps[phone] ?? 0]
        Self.phoneSteps[phone] = min(EnterSMSCodeCountdownLegs.count - 1, (Self.phoneSteps[phone] ?? 0) + 1)
        timer?.invalidate()
        startTimer()
        setResendCountdown()
    }

    func backTapped() {
        coordinatorIO.goBack.send()
    }

    func infoTapped() {
        coordinatorIO.showInfo.send()
    }

    // MARK: -

    var coordinatorIO: CoordinatorIO = .init()

    private var timer: Timer?

    init(phone: String) {
        self.phone = phone
        countdown = countdownSteps[Self.phoneSteps[phone] ?? 0]

        super.init()

        Self.phoneSteps[phone] = Self.phoneSteps[phone] ?? 1

        bind()
        startTimer()
        RunLoop.current.add(timer!, forMode: .common)
    }

    func bind() {
        coordinatorIO
            .error
            .receive(on: RunLoop.main)
            .sinkAsync { error in
                if let serviceError = error as? APIGatewayError {
                    switch serviceError {
                    case .invalidOTP:
                        self.showCodeError(error: EnterSMSCodeViewModelError.incorrectCode)
                    case .youRequestOTPTooOften:
                        return
                    default:
                        self.showError(error: error)
                    }
                } else {
                    self.showError(error: error)
                }
            }
            .store(in: &subscriptions)

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
        guard !isLoading else { return }
        coordinatorIO.onConfirm.send(code)
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
        let error: PassthroughSubject<Error?, Never> = .init()
        let onConfirm: PassthroughSubject<String, Never> = .init()
        let onResend: PassthroughSubject<Void, Never> = .init()
        let showInfo: PassthroughSubject<Void, Never> = .init()
        let goBack: PassthroughSubject<Void, Never> = .init()
    }

    enum EnterSMSCodeViewModelError: Error {
        case incorrectCode
    }
}
