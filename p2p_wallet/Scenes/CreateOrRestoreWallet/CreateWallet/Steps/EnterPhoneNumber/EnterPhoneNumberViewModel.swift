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
        coordinatorIO.selectFlag.send(selectedCountry)
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
        var selectFlag: PassthroughSubject<Country?, Never> = .init()
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
                }.eraseToAnyPublisher(),
            coordinatorIO.countrySelected.compactMap { $0?.dialCode }.eraseToAnyPublisher()
        )
            .assign(to: \.phone, on: self)
            .store(in: &cancellable)

        $phone.removeDuplicates().filter { $0 != nil }.map { phone -> Bool in
            guard let exampleNumber = self.exampleNumberWith(phone: phone ?? "") else {
                return true
            }
            return phone?
                .replacingOccurrences(of: "+", with: "")
                .starts(with: String(exampleNumber.countryCode)) ?? false
        }.sink {
            self.showInputError(error: $0 ? nil : L10n.sorryWeDonTKnowASuchCountry)
            if !$0 {
                self.flag = "🏴"
            } else {
                var country = ""
                if let parsed = try? self.phoneNumberKit.parse(self.phone ?? "", ignoreType: true) {
                    country = parsed.regionID ?? self.partialFormatter.currentRegion
                } else {
                    _ = self.partialFormatter.nationalNumber(from: self.phone ?? "")
                    country = self.partialFormatter.currentRegion
                }
                self.flag = Self.getFlag(from: country)
            }
        }.store(in: &cancellable)

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
