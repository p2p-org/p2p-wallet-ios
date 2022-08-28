import Combine
import CountriesAPI
import Foundation
import Onboarding
import PhoneNumberKit
import Reachability
import Resolver

final class EnterPhoneNumberViewModel: BaseOTPViewModel {
    private static let defaultConstantPlaceholder = "+44 7400 123456"
    private var cancellable = Set<AnyCancellable>()
    private lazy var phoneNumberKit = PhoneNumberKit()
    private lazy var partialFormatter: PartialFormatter = .init(
        phoneNumberKit: phoneNumberKit,
        withPrefix: true
    )

    // MARK: -

    @Injected private var reachability: Reachability
    @Injected private var notificationService: NotificationService

    @Published public var phone: String?
    @Published public var flag: String = ""
    @Published public var phonePlaceholder: String?
    @Published public var isButtonEnabled: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var inputError: String?
    @Published public var selectedCountry: Country?

    func buttonTaped() {
        guard
            let phone = phone,
            !isLoading,
            reachability.check()
        else { return }
        coordinatorIO.phoneEntered.send(phone.replacingOccurrences(of: " ", with: ""))
    }

    func selectCountryTap() {
        if let selectedCountry = selectedCountry {
            coordinatorIO.selectCode.send(selectedCountry.code)
        } else if
            let number = phone,
            let phoneNumber = exampleNumberWith(phone: number),
            let regionId = phoneNumber.regionID
        {
            coordinatorIO.selectCode.send(regionId)
        }
    }

    @MainActor
    private func showInputError(error: String?) {
        inputError = error
    }

    // MARK: -

    struct CoordinatorIO {
        // Input
        var error: PassthroughSubject<Error?, Never> = .init()
        var countrySelected: PassthroughSubject<Country?, Never> = .init()
        // Output
        var selectCode: PassthroughSubject<String?, Never> = .init()
        var phoneEntered: PassthroughSubject<String, Never> = .init()
    }

    // MARK: -

    var coordinatorIO: CoordinatorIO = .init()

    override init() {
        super.init()
        bind()
    }

    func bind() {
        coordinatorIO
            .error
            .receive(on: RunLoop.main)
            .sinkAsync { error in
                if let serviceError = error as? APIGatewayError, serviceError == .invalidRequest {
                    self.showInputError(error: "")
                } else if error is UndefinedAPIGatewayError {
                    self.notificationService.showDefaultErrorNotification()
                } else {
                    self.showError(error: error)
                }
            }
            .store(in: &subscriptions)

        Publishers.MergeMany(
            $phone.removeDuplicates()
                .debounce(for: 0.0, scheduler: DispatchQueue.main)
                .map {
                    guard let exampleNumber = self.exampleNumberWith(phone: $0 ?? "") else {
                        return Self.defaultConstantPlaceholder
                    }
                    let formatted = self.phoneNumberKit.format(exampleNumber, toType: .international)
                    let newFormatted = formatted
                        .replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
                        .replacingOccurrences(of: "-", with: " ")
                    guard $0 != nil else {
                        return Self.format(with: newFormatted, phone: String(exampleNumber.countryCode))
                    }
                    return Self.format(with: newFormatted, phone: $0 ?? "")
                }
                .eraseToAnyPublisher(),
            coordinatorIO.countrySelected
                .compactMap { $0?.dialCode }
                .eraseToAnyPublisher()
        )
            .assign(to: \.phone, on: self)
            .store(in: &cancellable)

        $phone.removeDuplicates().filter { $0 != nil }.sink { phone in
            guard let exampleNumber = self.exampleNumberWith(phone: phone ?? "") else { return }
            let countryCode = "\(exampleNumber.countryCode)"

            var country = ""
            if let parsed = try? self.phoneNumberKit.parse(countryCode, ignoreType: true) {
                country = parsed.regionID ?? self.partialFormatter.currentRegion
            } else {
                _ = self.partialFormatter.nationalNumber(from: countryCode)
                country = self.partialFormatter.currentRegion
            }
            self.flag = Self.getFlag(from: country)

            self.showInputError(error: !self.flag.isEmpty ? nil : L10n.sorryWeDonTKnowASuchCountry)

            if self.flag.isEmpty {
                self.flag = "🏴"
            }
        }.store(in: &cancellable)

        coordinatorIO.countrySelected
            .compactMap { $0?.emoji }
            .debounce(for: .seconds(0.01), scheduler: DispatchQueue.main)
            .assign(to: \.flag, on: self)
            .store(in: &cancellable)

        Publishers.MergeMany(
            coordinatorIO.countrySelected.map { $0?.dialCode }.eraseToAnyPublisher(),
            $phone.removeDuplicates().eraseToAnyPublisher()
        ).map { vv -> String in
            _ = self.partialFormatter.nationalNumber(from: vv ?? "")
            let country = self.partialFormatter.currentRegion
            guard let number = self.phoneNumberKit.getExampleNumber(forCountry: country) else {
                return Self.defaultConstantPlaceholder
            }
            return self.phoneNumberKit
                .format(number, toType: .international)
                .replacingOccurrences(of: "-", with: " ")
        }
        .assign(to: \.phonePlaceholder, on: self)
        .store(in: &cancellable)

        $phone.removeDuplicates().map { [weak self] in
            (try? self?.phoneNumberKit.parse($0 ?? "", ignoreType: true)) != nil
        }
        .assign(to: \.isButtonEnabled, on: self)
        .store(in: &cancellable)

        coordinatorIO.countrySelected
            .eraseToAnyPublisher()
            .assign(to: \.selectedCountry, on: self)
            .store(in: &cancellable)
    }

    func exampleNumberWith(phone: String) -> PhoneNumber? {
        _ = partialFormatter.nationalNumber(from: phone)
        let country = partialFormatter.currentRegion
        return phoneNumberKit.getExampleNumber(forCountry: country)
    }

    func clearedPhoneString(phone: String) -> String {
        phone.filter("0123456789+".contains)
    }

    // MARK: -

    static func getFlag(from countryCode: String) -> String {
        countryCode
            .unicodeScalars
            .map { 127_397 + $0.value }
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }

    static func format(with mask: String, phone: String) -> String {
        if phone == "+" { return phone }
        let numbers = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        var result = ""
        var index = numbers.startIndex // numbers iterator

        // iterate over the mask characters until the iterator of numbers ends
        for ch in mask where index < numbers.endIndex {
            if ch == "X" {
                // mask requires a number in this place, so take the next one
                result.append(numbers[index])

                // move numbers iterator to the next index
                index = numbers.index(after: index)

            } else {
                result.append(ch) // just append a mask character
            }
        }
        return result
    }
}
