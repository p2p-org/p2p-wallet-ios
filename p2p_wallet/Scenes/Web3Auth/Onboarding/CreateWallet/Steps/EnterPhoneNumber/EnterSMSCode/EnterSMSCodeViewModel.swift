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

    var attemptCounter: Wrapper<ResendCounter>

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

    @Published var phone: String
    @Published var code: String = ""
    /// Input error field
    @Published var codeError: String?
    @Published var isLoading: Bool = false
    @Published var resendEnabled: Bool = false
    @Published var resendText: String = ""
    @Published var isButtonEnabled: Bool = false
    var phoneText: String {
        strategy == .striga ? L10n.weHaveSentACodeTo : L10n.checkTheNumber
    }

    var title: String {
        strategy == .striga ? L10n.enterConfirmationCode : L10n.theCodeFromSMS
    }

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

    private weak var timer: Timer?

    deinit {
        timer?.invalidate()
    }

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
        coordinatorIO.onStart.sendProcess { [weak self] error in
            if let error {
                self?.coordinatorIO.error.send(error)
            }
        }

        switch strategy {
        case .create:
            analyticsManager.log(event: .createSmsScreen)
        case .restore:
            analyticsManager.log(event: .restoreSmsScreen)
        case .striga:
            break
        }
    }

    func bind() {
        coordinatorIO
            .error
            .receive(on: RunLoop.main)
            .sinkAsync { [weak self] error in
                if let self, let serviceError = error as? APIGatewayError {
                    switch serviceError {
                    case .invalidOTP:
                        self.showCodeError(error: EnterSMSCodeViewModelError.incorrectCode)
                    case .retry:
                        self.notificationService.showDefaultErrorNotification()
                    default:
                        self.showError(error: error)
                    }
                } else if (error as? NSError)?.isNetworkConnectionError == true {
                    self?.notificationService.showConnectionErrorNotification()
                } else if error is UndefinedAPIGatewayError {
                    self?.notificationService.showDefaultErrorNotification()
                } else {
                    self?.showError(error: error)
                }
            }
            .store(in: &subscriptions)

        $code.removeDuplicates()
            .debounce(for: 0.0, scheduler: DispatchQueue.main)
            .map { Self.format(code: $0) }
            .handleEvents(receiveOutput: { [weak self] aCode in
                self?.showCodeError(error: nil)
                self?.rawCode = Self.prepareRawCode(code: aCode)
            })
            .assignWeak(to: \.code, on: self)
            .store(in: &subscriptions)
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

    // MARK: -

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task {
                await MainActor.run { [weak self] in
                    self?.countdown -= 1
                    self?.setResendCountdown()
                    if self?.countdown == 0 {
                        self?.timer?.invalidate()
                        self?.setResendCountdown()
                        return
                    }
                }
            }
        }
        timer?.fire()
    }

    private func setResendCountdown() {
        let secs = countdown <= 0 ? "" : " \(countdown) sec"
        resendText = secs.isEmpty ? L10n.tapToResend : L10n.resendSMS(secs)
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

extension EnterSMSCodeViewModel {
    struct CoordinatorIO {
        let error: PassthroughSubject<Error?, Never> = .init()
        let onConfirm: PassthroughSubject<String, Never> = .init()
        let onResend: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
        let onStart: PassthroughSubject<ReactiveProcess<Void>, Never> = .init()
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
        case striga
    }
}

private extension Substring {
    func asString() -> String {
        String(self)
    }
}
