import BankTransfer
import Combine
import Foundation
import Resolver

class WithdrawViewModel: BaseViewModel, ObservableObject {
    typealias FieldStatus = StrigaFormTextFieldStatus

    // MARK: - Dependencies

    @Injected private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>
    @Injected private var notificationService: NotificationService

    // MARK: - Properties

    @Published var IBAN: String = ""
    @Published var BIC: String = ""
    @Published var receiver: String = ""
    @Published var actionTitle: String = L10n.withdraw
    @Published var isDataValid = false
    @Published var fieldsStatuses = [WithdrawViewField: FieldStatus]()
    @Published var isLoading = false
    @Published var actionHasBeenTapped = false

    private let gatheringCompletedSubject = PassthroughSubject<(IBAN: String, BIC: String), Never>()
    public var gatheringCompletedPublisher: AnyPublisher<(IBAN: String, BIC: String), Never> {
        gatheringCompletedSubject.eraseToAnyPublisher()
    }
    private let paymentInitiatedSubject = PassthroughSubject<String, Never>()
    public var paymentInitiatedPublisher: AnyPublisher<String, Never> {
        paymentInitiatedSubject.eraseToAnyPublisher()
    }
    private let strategy: WithdrawStrategy

    init(
        withdrawalInfo: StrigaWithdrawalInfo,
        strategy: WithdrawStrategy
        
    ) {
        self.strategy = strategy
        super.init()

        self.IBAN = withdrawalInfo.IBAN ?? ""
        self.BIC = withdrawalInfo.BIC ?? ""
        self.receiver = withdrawalInfo.receiver

        Publishers.CombineLatest3($IBAN, $BIC, $actionHasBeenTapped)
            .drop(while: { _, _, actionHasBeenTapped in
                !actionHasBeenTapped
            })
            .map { [unowned self] iban, bic, _ in
                [
                    WithdrawViewField.IBAN: checkIBAN(iban),
                    WithdrawViewField.BIC: checkBIC(bic)
                ]
            }
            .handleEvents(receiveOutput: { [unowned self] fields in
                isDataValid = fields.values.filter({ status in
                    status == .valid
                }).count == fields.keys.count
                actionTitle = isDataValid ? L10n.withdraw : L10n.checkYourData
            })
            .assignWeak(to: \.fieldsStatuses, on: self)
            .store(in: &subscriptions)

        $IBAN
            .debounce(for: 0.0, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.formatIBAN() }
            .assignWeak(to: \.IBAN, on: self)
            .store(in: &subscriptions)

        $BIC
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.uppercased() }
            .assignWeak(to: \.BIC, on: self)
            .store(in: &subscriptions)
    }

    func action() async {
        actionHasBeenTapped = true
        guard !isLoading, checkIBAN(IBAN) == .valid, checkBIC(BIC) == .valid else {
            return
        }

        isLoading = true
        defer {
            isLoading = false
        }
        let info = StrigaWithdrawalInfo(IBAN: IBAN.filterIBAN(), BIC: BIC, receiver: receiver)
        // Save to local
        await save(info: info)

        switch strategy {
        case .gathering:
            // Complete the flow
            gatheringCompletedSubject.send((IBAN.filterIBAN(), BIC))
        case let .confirmation(params):
            // Initiate SEPA payment
            guard let challengeId = await initiateSEPAPayment(params: params, info: info) else { return }
            paymentInitiatedSubject.send(challengeId)
        }
    }

    private func save(info: StrigaWithdrawalInfo) async {
        do {
            try await bankTransferService.value.saveWithdrawalInfo(info: info)
        } catch {
            notificationService.showDefaultErrorNotification()
        }
    }

    private func initiateSEPAPayment(params: WithdrawConfirmationParameters, info: StrigaWithdrawalInfo) async -> String? {
        do {
            guard let userId = await bankTransferService.value.repository.getUserId() else {
                throw BankTransferError.missingUserId
            }
            let challengeId = try await bankTransferService.value.repository.initiateSEPAPayment(
                userId: userId,
                accountId: params.accountId,
                amount: params.amount,
                iban: info.IBAN ?? "",
                bic: info.BIC ?? ""
            )
            return challengeId
        } catch let error as NSError where error.isNetworkConnectionError {
            notificationService.showConnectionErrorNotification()
            return nil
        } catch {
            notificationService.showDefaultErrorNotification()
            return nil
        }
    }
    
    private func checkIBAN(_ iban: String) -> FieldStatus {
        let filteredIBAN = iban.filterIBAN()
        if filteredIBAN.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(error: WithdrawViewFieldError.empty.text)
        }
        return filteredIBAN.passesMod97Check() ? .valid : .invalid(error: WithdrawViewFieldError.invalidIBAN.text)
    }

    private func checkBIC(_ bic: String) -> FieldStatus {
        let bic = bic.trimmingCharacters(in: .whitespacesAndNewlines)
        if bic.isEmpty {
            return .invalid(error: WithdrawViewFieldError.empty.text)
        }
        return bic.passesBICCheck() ? .valid : .invalid(error: WithdrawViewFieldError.invalidBIC.text)
    }
}

// Validation
private extension String {
    private func mod97() -> Int {
        let symbols: [Character] = Array(self)
        let swapped = symbols.dropFirst(4) + symbols.prefix(4)

        let mod: Int = swapped.reduce(0) { (previousMod, char) in
            let value = Int(String(char), radix: 36)! // "0" => 0, "A" => 10, "Z" => 35
            let factor = value < 10 ? 10 : 100
            return (factor * previousMod + value) % 97
        }
        return mod
    }

    func passesMod97Check() -> Bool {
        guard count >= 4 else {
            return false
        }

        let uppercase = uppercased()

        guard uppercase.range(of: "^[0-9A-Z]*$", options: .regularExpression) != nil else {
            return false
        }
        return (uppercase.mod97() == 1)
    }

    func passesBICCheck() -> Bool {
        let bicRegex = "^([A-Za-z]{4}[A-Za-z]{2})([A-Za-z0-9]{2})([A-Za-z0-9]{3})?$"
        let bicTest = NSPredicate(format: "SELF MATCHES %@", bicRegex)
        return bicTest.evaluate(with: self)
    }

    func filterIBAN() -> String {
        // Use a character set containing allowed characters (alphanumeric and spaces)
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        // Remove any characters not in the allowed set
        return self.components(separatedBy: allowedCharacterSet.inverted).joined()
    }
}

enum WithdrawViewFieldError {
    case empty
    case invalidIBAN
    case invalidBIC

    var text: String {
        switch self {
        case .empty:
            return L10n.couldNotBeEmpty
        case .invalidIBAN:
            return L10n.invalidIBAN
        case .invalidBIC:
            return L10n.invalidBIC
        }
    }
}
