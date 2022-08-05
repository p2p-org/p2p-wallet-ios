import Combine
import CountriesAPI
import Foundation
import PhoneNumberKit

final class EnterPhoneNumberViewModel: BaseViewModel {
    private static let defaultConstantPlaceholder = "+44 7400 123456"
    private var cancellable = Set<AnyCancellable>()
    private lazy var phoneNumberKit = PhoneNumberKit()
    private lazy var partialFormatter: PartialFormatter = .init(
        phoneNumberKit: self.phoneNumberKit,
        withPrefix: true
    )

    // MARK: -

    @Published public var phone: String?
    @Published public var flag: String = ""
    @Published public var phonePlaceholder: String?
    @Published public var isButtonEnabled: Bool = false

    func buttonTaped() {
        guard let phone = phone else {
            return
        }
        coordinatorIO.phoneEntered.send(phone)
    }

    func selectCountryTap() {
        coordinatorIO.selectFlag.send()
    }

    // MARK: -

    struct CoordinatorIO {
        // Input
        var countrySelected: PassthroughSubject<Country?, Never> = .init()
        // Output
        var selectFlag: PassthroughSubject<Void, Never> = .init()
        var phoneEntered: PassthroughSubject<String, Never> = .init()
    }

    // MARK: -

    var coordinatorIO: CoordinatorIO = .init()

    override init() {
        super.init()
        bind()
    }

    func bind() {
        $phone
            .dropFirst()
            .removeDuplicates()
            .map {
                ($0 ?? "")
                    .split(separator: " ")
                    .map(String.init)
                    .joined(separator: "")
                    .isPhoneNumber
            }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &cancellable)

        Publishers.MergeMany(
            $phone.removeDuplicates()
                .debounce(for: 0.0, scheduler: DispatchQueue.main)
                .map {
                    _ = self.partialFormatter.nationalNumber(from: $0 ?? "")
                    let country = self.partialFormatter.currentRegion
                    guard let exampleNumber = self.phoneNumberKit.getExampleNumber(forCountry: country) else {
                        return Self.defaultConstantPlaceholder
                    }
                    let formatted = self.phoneNumberKit.format(exampleNumber, toType: .international)
                    var newFormatted = formatted
                        .replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
                        .replacingOccurrences(of: "-", with: " ")
                    newFormatted.append("XXXXXX")
                    return Self.format(with: newFormatted, phone: $0 ?? "")
                }.eraseToAnyPublisher(),
            coordinatorIO.countrySelected.compactMap { $0?.dialCode }.eraseToAnyPublisher()
        )
            .assign(to: \.phone, on: self)
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

        $phone.removeDuplicates().map {
            _ = self.partialFormatter.nationalNumber(from: $0 ?? "")
            let country = self.partialFormatter.currentRegion
            return Self.getFlag(from: country)
        }
        .assign(to: \.flag, on: self)
        .store(in: &cancellable)
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
