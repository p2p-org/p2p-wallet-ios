import BankTransfer
import Combine
import Foundation
import Resolver

class WithdrawViewModel: BaseViewModel, ObservableObject {
    typealias FieldStatus = StrigaFormTextFieldStatus

    // MARK: -

    @Injected var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>
    @Injected var notificationService: NotificationService

    // MARK: -

    @Published var IBAN: String = ""
    @Published var BIC: String = ""
    @Published var receiver: String = ""
    @Published var actionTitle: String = "Withdraw"
    @Published var isDataValid = false
    @Published var fieldsStatuses = [WithdrawViewField: FieldStatus]()
    @Published var isLoading = false
    @Published private var actionHasBeenTapped = false

    private let actionCompletedSubject = PassthroughSubject<Void, Never>()
    public var actionCompletedPublisher: AnyPublisher<Void, Never> {
        actionCompletedSubject.eraseToAnyPublisher()
    }

    init(
        withdrawalInfo: StrigaWithdrawalInfo
    ) {
        super.init()

        self.IBAN = withdrawalInfo.IBAN ?? ""
        self.BIC = withdrawalInfo.BIC ?? ""
        self.receiver = withdrawalInfo.receiver

        Publishers.CombineLatest3($IBAN, $BIC, $actionHasBeenTapped)
            .drop(while: { _, _, actionHasBeenTapped in
                !actionHasBeenTapped
            })
            .map { iban, bic, _ in
                [
                    WithdrawViewField.IBAN: self.checkIBAN(iban),
                    WithdrawViewField.BIC: self.checkBIC(bic)
                ]
            }
            .assignWeak(to: \.fieldsStatuses, on: self)
            .store(in: &subscriptions)

        $IBAN
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { self.formatIBAN($0) }
            .assignWeak(to: \.IBAN, on: self)
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
        // Save to local
        do {
            try await bankTransferService.value.saveWithdrawalInfo(info:
                .init(
                    IBAN: IBAN.filterIBAN(),
                    BIC: BIC,
                    receiver: receiver
                )
            )
        } catch {
            notificationService.showDefaultErrorNotification()
        }
        actionCompletedSubject.send()
    }

    func formatIBAN(_ iban: String) -> String {
        // Remove any spaces or special characters from the input string
        let cleanedIBAN = iban.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()

        // Check if the IBAN is empty or not valid (less than 4 characters)
        guard cleanedIBAN.count >= 4 else {
            return cleanedIBAN
        }

        // Create a formatted IBAN by grouping characters in blocks of four
        var formattedIBAN = ""
        var index = cleanedIBAN.startIndex

        while index < cleanedIBAN.endIndex {
            let nextIndex = cleanedIBAN.index(index, offsetBy: 4, limitedBy: cleanedIBAN.endIndex) ?? cleanedIBAN.endIndex
            let block = cleanedIBAN[index..<nextIndex]
            formattedIBAN += String(block)
            if nextIndex != cleanedIBAN.endIndex {
                formattedIBAN += " "
            }
            index = nextIndex
        }

        return formattedIBAN
    }

    private func checkIBAN(_ iban: String) -> FieldStatus {
        let filteredIBAN = iban.filterIBAN()
        if filteredIBAN.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(error: WithdrawViewFieldError.empty.rawValue)
        }
        return filteredIBAN.passesMod97Check() ? .valid : .invalid(error: WithdrawViewFieldError.invalidIBAN.rawValue)
    }

    private func checkBIC(_ bic: String) -> FieldStatus {
        let bic = bic.trimmingCharacters(in: .whitespacesAndNewlines)
        if bic.isEmpty {
            return .invalid(error: WithdrawViewFieldError.empty.rawValue)
        }
        return bic.passesBICCheck() ? .valid : .invalid(error: WithdrawViewFieldError.invalidBIC.rawValue)
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

enum WithdrawViewFieldError: String {
    case empty = "Could not be empty"
    case invalidIBAN = "Invalid IBAN"
    case invalidBIC = "Invalid BIC"
}
