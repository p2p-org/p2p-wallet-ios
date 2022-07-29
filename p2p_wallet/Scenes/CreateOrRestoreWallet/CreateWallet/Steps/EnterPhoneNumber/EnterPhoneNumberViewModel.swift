import Combine
import CountriesAPI
import Foundation
import PhoneNumberKit

final class EnterPhoneNumberViewModel: BaseViewModel, ViewModelType {
    private static let defaultConstantPlaceholder = "+44 7400 123456"
    private var cancellable = Set<AnyCancellable>()

    // MARK: -

    struct Input {
        var phone: CurrentValueSubject<String?, Never> = .init(nil)
        var button: PassthroughSubject<Void, Never> = .init()
        var selectCountryTapped: PassthroughSubject<Void, Never> = .init()
    }

    struct Output {
        let phone: AnyPublisher<String?, Never>
        let flag: AnyPublisher<String, Never>
        let isButtonEnabled: AnyPublisher<Bool, Never>
        let phonePlaceholder: AnyPublisher<String, Never>
    }

    struct CoordinatorIO {
        var selectFlag: PassthroughSubject<Void, Never> = .init()
        var flagSelected: PassthroughSubject<Country?, Never> = .init()
    }

    // MARK: -

    var input: Input
    var output: Output
    var coordinatorIO: CoordinatorIO = .init()

    override init() {
        input = Input()

        let phoneNumberKit = PhoneNumberKit()
        let partialFormatter: PartialFormatter = .init(
            phoneNumberKit: phoneNumberKit,
            withPrefix: true
        )

        output = Output(
            phone: Publishers.MergeMany(
                Self.phone(
                    phone: input.phone,
                    phoneNumberKit: phoneNumberKit,
                    partialFormatter: partialFormatter
                ),
                coordinatorIO.flagSelected.compactMap { $0?.dialCode }.eraseToAnyPublisher()
            ).eraseToAnyPublisher(),
            flag: Publishers.MergeMany(
                Self.flag(
                    phone: input.phone,
                    partialFormatter: partialFormatter
                ),
                Self.flag(country: coordinatorIO.flagSelected)
            ).eraseToAnyPublisher(),
            isButtonEnabled: input.phone
                .map { $0?.split(separator: " ").map(String.init).joined(separator: "").isPhoneNumber ?? false }
                .eraseToAnyPublisher(),
            phonePlaceholder: Self.placeholder(
                phone: input.phone,
                country: coordinatorIO.flagSelected,
                phoneNumberKit: phoneNumberKit,
                partialFormatter: partialFormatter
            )
        )
        super.init()

        bind()
    }

    func bind() {
        input.selectCountryTapped.sink { [weak self] _ in
            self?.coordinatorIO.selectFlag.send()
        }.store(in: &cancellable)
    }

    // MARK: -

    static func phone(
        phone: CurrentValueSubject<String?, Never>,
        phoneNumberKit: PhoneNumberKit,
        partialFormatter: PartialFormatter
    ) -> AnyPublisher<String?, Never> {
        phone.map {
            _ = partialFormatter.nationalNumber(from: $0 ?? "")
            let country = partialFormatter.currentRegion
            guard let exampleNumber = phoneNumberKit.getExampleNumber(forCountry: country) else {
                return Self.defaultConstantPlaceholder
            }
            let formatted = phoneNumberKit.format(exampleNumber, toType: .international)
            var newFormatted = formatted
                .replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
                .replacingOccurrences(of: "-", with: " ")
            newFormatted.append("XXXXXX")
            return Self.format(with: newFormatted, phone: $0 ?? "")
        }.eraseToAnyPublisher()
    }

    static func placeholder(
        phone: CurrentValueSubject<String?, Never>,
        country: PassthroughSubject<Country?, Never>,
        phoneNumberKit: PhoneNumberKit,
        partialFormatter: PartialFormatter
    ) -> AnyPublisher<String, Never> {
        Publishers.MergeMany(
            country.map { $0?.dialCode }.eraseToAnyPublisher(),
            phone.eraseToAnyPublisher()
        ).map {
            _ = partialFormatter.nationalNumber(from: $0 ?? "")
            let country = partialFormatter.currentRegion
            guard let number = phoneNumberKit.getExampleNumber(forCountry: country) else {
                return Self.defaultConstantPlaceholder
            }
            return phoneNumberKit.format(number, toType: .international)
                .replacingOccurrences(of: "-", with: " ")
        }.eraseToAnyPublisher()
    }

    static func flag(
        phone: CurrentValueSubject<String?, Never>,
        partialFormatter: PartialFormatter
    ) -> AnyPublisher<String, Never> {
        phone.map {
            _ = partialFormatter.nationalNumber(from: $0 ?? "")
            let country = partialFormatter.currentRegion
            return Self.getFlag(from: country)
        }.eraseToAnyPublisher()
    }

    static func flag(country: PassthroughSubject<Country?, Never>) -> AnyPublisher<String, Never> {
        country.filter { $0 != nil }.compactMap { country in
            Self.getFlag(from: country!.code)
        }.eraseToAnyPublisher()
    }

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

extension String {
    var isPhoneNumber: Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: count))
            if let res = matches.first {
                return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == count
            } else {
                return false
            }
        } catch {
            return false
        }
    }
}
