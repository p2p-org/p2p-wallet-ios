import AnalyticsManager
import Combine
import CountriesAPI
import Foundation
import Onboarding
import PhoneNumberKit
import Reachability
import Resolver
import SwiftyUserDefaults

@MainActor
final class EnterSMSCodeViewModel: BaseOTPViewModel {
    // MARK: -

    private var cancellable = Set<AnyCancellable>()

    private let attemptCounter: Wrapper<ResendCounter>
    private var countdown: Int
    private static let codeLength = 6
    private let strategy: Strategy

    // MARK: -

    @Injected private var reachability: Reachability
    @Injected private var notificationService: NotificationService
    @Injected private var analyticsManager: AnalyticsManager

    private var rawCode: String = "" {
        didSet {
            let validated = rawCode.count == Self.codeLength
            isButtonEnabled = validated
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
        guard !isLoading, reachability.check() else { return }
        coordinatorIO.onConfirm.send(rawCode)
    }

    @MainActor
    func resendButtonTapped() {
        guard
            !isLoading,
            reachability.check()
        else { return }

        isLoading = true
        coordinatorIO.onResend.sendProcess { [weak self] error in
            // Setup timer
            DispatchQueue.main.async {
                if let error = error {
                    self?.coordinatorIO.error.send(error)
                    self?.isLoading = false
                    return
                }
                self?.syncTimer()
                self?.isLoading = false
            }
        }
    }

    @MainActor
    func syncTimer() {
        countdown = Int(Date().ceiled().distance(to: attemptCounter.value.until))
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

    init(phone: String, attemptCounter: Wrapper<ResendCounter>, strategy: Strategy) {
        self.phone = phone
        self.strategy = strategy
        self.attemptCounter = attemptCounter
        countdown = Int(Date().ceiled().distance(to: attemptCounter.value.until))
        super.init()

        bind()
        startTimer()
        RunLoop.current.add(timer!, forMode: .common)
    }

    func viewDidLoad() {
        switch strategy {
        case .create:
            analyticsManager.log(event: AmplitudeEvent.createSmsScreen)
        case .restore:
            analyticsManager.log(event: AmplitudeEvent.restoreSmsScreen)
        }
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
                    case .retry:
                        self.notificationService.showDefaultErrorNotification()
                    default:
                        self.showError(error: error)
                    }
                } else if error is UndefinedAPIGatewayError {
                    self.notificationService.showDefaultErrorNotification()
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
        timer?.fire()
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
        let onResend: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let showInfo: PassthroughSubject<Void, Never> = .init()
        let goBack: PassthroughSubject<Void, Never> = .init()
    }

    enum EnterSMSCodeViewModelError: Error {
        case incorrectCode
    }
}

private extension Date {
    func ceiled() -> Date {
        let date = ceil(Date().timeIntervalSince1970)
        return Date(timeIntervalSince1970: date)
    }
}

// MARK: - Strategy

extension EnterSMSCodeViewModel {
    enum Strategy {
        case create
        case restore
    }
}
