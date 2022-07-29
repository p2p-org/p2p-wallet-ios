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

final class EnterSMSCodeViewModel: BaseViewModel, ViewModelType {
    @Injected static var smsService: SMSService

    // MARK: -

    private let errorSubject: PassthroughSubject<String?, Never> = .init()
    private let resendSubject: PassthroughSubject<String?, Never> = .init()
    private let resendEnabledSubject: PassthroughSubject<Bool, Never> = .init()
    private let isLoadingSubject: PassthroughSubject<Bool, Never> = .init()

    // MARK: -

    struct Input {
        var code: CurrentValueSubject<String, Never> = .init("")
        var button: PassthroughSubject<Void, Never> = .init()
        var resendButtonTapped: PassthroughSubject<Void, Never> = .init()
        var onBack: PassthroughSubject<Void, Never> = .init()
        var onInfo: PassthroughSubject<Void, Never> = .init()
    }

    struct Output {
        var resendText: AnyPublisher<String?, Never>
        var resendEnabled: AnyPublisher<Bool, Never>
        var isButtonEnabled: AnyPublisher<Bool, Never>
        var error: AnyPublisher<String?, Never>
        var code: AnyPublisher<String?, Never>
        var isLoading: AnyPublisher<Bool, Never>
    }

    struct CoordinatorIO {
        var isConfirmed: PassthroughSubject<Bool, Never> = .init()
        var showInfo: PassthroughSubject<Void, Never> = .init()
        var goBack: PassthroughSubject<Void, Never> = .init()
    }

    // MARK: -

    private var cancellable = Set<AnyCancellable>()
    private var countdown = EnterSMSCodeCountdown
    private var phone: String

    // MARK: -

    var input: Input
    var output: Output
    var coordinatorIO: CoordinatorIO = .init()

    private var timer: Timer?

    init(phone: String) {
        input = Input()
        output = Output(
            resendText: resendSubject.eraseToAnyPublisher(),
            resendEnabled: resendEnabledSubject.eraseToAnyPublisher(),
            isButtonEnabled: input.code
                .map {
                    Self.smsService.isValidCodeFormat(code: $0.replacingOccurrences(of: " ", with: ""))
                }
                .eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            code: input.code.map { Self.format(code: $0) }.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher()
        )

        self.phone = phone

        super.init()

        bind()

        Task {
            do {
                try await Self.smsService.sendConfirmationCode(phone: phone)
            } catch let err {
                errorSubject.send(err.readableDescription)
            }
        }

        startTimer()
        RunLoop.current.add(timer!, forMode: .common)
    }

    func bind() {
        input.button
            .withLatestFrom(input.code)
            .handleEvents(receiveOutput: { _ in
                self.isLoadingSubject.send(true)
                self.timer?.invalidate()
            })
            .flatMap { code in
                Future { promise in
                    Task {
                        promise(.success(try await Self.smsService.confirm(phone: self.phone, code: code)))
                    }
                }
            }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sinkAsync(receiveValue: { [weak self] result in
                guard let self = self else { return }
                self.coordinatorIO.isConfirmed.send(result)
                self.isLoadingSubject.send(false)
            }).store(in: &cancellable)

        input.resendButtonTapped.sinkAsync { _ in
            self.countdown = EnterSMSCodeCountdown
            self.resendEnabledSubject.send(false)
            self.timer?.invalidate()
            self.startTimer()
            try await Self.smsService.sendConfirmationCode(phone: self.phone)
        }.store(in: &cancellable)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.countdown -= 1
            let secs = self.countdown <= 0 ? "" : " (\(self.countdown)s)"
            self.resendSubject.send(" Tap to resend\(secs)")
            self.resendEnabledSubject.send(false)

            if self.countdown == 0 {
                self.timer?.invalidate()
                self.resendEnabledSubject.send(true)
                return
            }
        }
    }

    static func format(code: String) -> String {
        code.replacingOccurrences(of: " ", with: "").separate(every: 3, with: " ")
    }
}

extension String {
    func separate(every: Int, with separator: String) -> String {
        String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0 ..< min($0 + every, Array(self).count)])
        }.joined(separator: separator))
    }
}
