import Combine
import CountriesAPI
import Foundation
import Onboarding
import PhoneNumberKit
import Reachability
import Resolver

final class EnterPhoneNumberViewModel: BaseOTPViewModel {
    private static let defaultCountry = Country(
        name: L10n.sorryWeDonTKnowASuchCountry,
        code: "",
        dialCode: "",
        emoji: "🏴"
    )

    private var cancellable = Set<AnyCancellable>()
    private lazy var phoneNumberKit = PhoneNumberKit()
    private lazy var partialFormatter: PartialFormatter = .init(
        phoneNumberKit: phoneNumberKit,
        withPrefix: true
    )

    // MARK: -

    @Injected private var reachability: Reachability
    @Injected private var notificationService: NotificationService
    @Injected private var countriesAPI: CountriesAPI

    // MARK: -

    @Published public var phone: String?
    @Published public var flag: String = ""
    @Published public var phonePlaceholder: String?
    @Published public var isButtonEnabled: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var inputError: String?
    @Published public var selectedCountry: Country = EnterPhoneNumberViewModel.defaultCountry

    let isBackAvailable: Bool

    func buttonTaped() {
        guard
            let phone = phone,
            !isLoading,
            reachability.check()
        else { return }
        coordinatorIO.phoneEntered.send(phone.replacingOccurrences(of: " ", with: ""))
    }

    func selectCountryTap() {
        coordinatorIO.selectCode.send((selectedCountry.dialCode, selectedCountry.code))
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
        var selectCode: PassthroughSubject<(String?, String?), Never> = .init()
        var phoneEntered: PassthroughSubject<String, Never> = .init()
        let helpClicked = PassthroughSubject<Void, Never>()
        let back: PassthroughSubject<Void, Never> = .init()
    }

    // MARK: -

    let coordinatorIO = CoordinatorIO()

    init(phone: String? = nil, isBackAvailable: Bool) {
        self.isBackAvailable = isBackAvailable
        super.init()

        Task {
            let countries = try await countriesAPI.fetchCountries()
            if let phone = phone {
                // In case we have an initial phone number
                let parsedRegion = try? self.phoneNumberKit.parse(phone).regionID?.lowercased()
                self.selectedCountry = countries.first(where: { country in
                    country.code == parsedRegion ?? PhoneNumberKit.defaultRegionCode().lowercased()
                }) ?? countries.first ?? EnterPhoneNumberViewModel.defaultCountry
                self.phone = phone
            } else {
                self.selectedCountry = countries.first(where: { country in
                    country.code == PhoneNumberKit.defaultRegionCode().lowercased()
                }) ?? countries.first ?? EnterPhoneNumberViewModel.defaultCountry
            }
        }

        bind()
    }

    func bind() {
        coordinatorIO.error
            .receive(on: RunLoop.main)
            .sinkAsync { error in
                if let serviceError = error as? APIGatewayError {
                    switch serviceError {
                    case .invalidRequest:
                        self.showInputError(error: "")
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

        Publishers.MergeMany(
            $phone.debounce(for: 0.0, scheduler: DispatchQueue.main)
                .removeDuplicates()
                .scan("") {
                    if self.clearedPhoneString(phone: $1 ?? "")
                        .starts(with: self.clearedPhoneString(phone: self.selectedCountry.dialCode)) == true
                    {
                        guard let exampleNumber = self.exampleNumberWith(phone: $0 ?? "") else {
                            return $1 ?? ""
                        }
                        let formattedExample = self.phoneNumberKit.format(exampleNumber, toType: .international)
                            .replacingOccurrences(of: "[0-9]", with: "X", options: .regularExpression)
                            .replacingOccurrences(of: "-", with: " ")
                        return Self.format(with: formattedExample, phone: $1 ?? "")
                    } else {
                        return $0
                    }
                }
                .compactMap { $0 }
                .eraseToAnyPublisher(),
            coordinatorIO.countrySelected
                .compactMap { $0?.dialCode }
                .filter {
                    !self.clearedPhoneString(phone: self.phone ?? "")
                        .starts(with: self.clearedPhoneString(phone: $0 ?? ""))
                }
                .eraseToAnyPublisher()
        )
            .assign(to: \.phone, on: self)
            .store(in: &cancellable)

        $selectedCountry.debounce(for: .seconds(0.01), scheduler: DispatchQueue.main)
            .compactMap(\.emoji)
            .assign(to: \.flag, on: self)
            .store(in: &cancellable)

        $selectedCountry
            .map(\.dialCode)
            .filter {
                !self.clearedPhoneString(phone: self.phone ?? "")
                    .starts(with: self.clearedPhoneString(phone: $0))
            }
            .compactMap { $0 }
            .assign(to: \.phone, on: self)
            .store(in: &cancellable)

        $phone.removeDuplicates()
            .compactMap { $0 }
            .map { [weak self] in
                guard let self = self else { return false }
                let phones = self.phoneNumberKit.parse(
                    [$0],
                    withRegion: self.selectedCountry.code,
                    ignoreType: false,
                    shouldReturnFailedEmptyNumbers: false
                )
                return !phones.isEmpty
            }
            .assign(to: \.isButtonEnabled, on: self)
            .store(in: &cancellable)

        coordinatorIO.countrySelected
            .eraseToAnyPublisher()
            .compactMap { $0 }
            .assign(to: \.selectedCountry, on: self)
            .store(in: &cancellable)
    }

    func exampleNumberWith(phone: String? = "") -> PhoneNumber? {
        _ = partialFormatter.nationalNumber(from: phone ?? "")
        let country = partialFormatter.currentRegion
        return phoneNumberKit.getExampleNumber(forCountry: country)
    }

    func clearedPhoneString(phone: String) -> String {
        phone.filter("0123456789+".contains)
    }

    func infoClicked() {
        coordinatorIO.helpClicked.send()
    }

    // MARK: -

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
