import Combine
import BankTransfer
import Resolver
import CountriesAPI
import PhoneNumberKit

final class StrigaRegistrationFirstStepViewModel: BaseViewModel, ObservableObject {

    enum Field {
        case email
        case phoneNumber
        case firstName
        case surname
        case dateOfBirth
        case countryOfBirth
    }

    // Dependencies
    @Injected private var service: BankTransferService

    // Data
    private var data: StrigaUserDetailsResponse?
    
    // Loading state
    @Published var isLoading = false

    // Fields
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var firstName: String = ""
    @Published var surname: String = ""
    @Published var dateOfBirth: String = ""
    @Published var countryOfBirth: String = ""

    // Other views
    @Published var actionTitle: String = L10n.next
    @Published var isDataValid = true // We need this flag to allow user enter at first whatever he/she likes and then validate everything
    let actionPressed = PassthroughSubject<Void, Never>()
    let openNextStep = PassthroughSubject<StrigaUserDetailsResponse, Never>()
    let chooseCountry = PassthroughSubject<Country?, Never>()
    let back = PassthroughSubject<Void, Never>()

    var fieldsStatuses = [Field: StrigaRegistrationTextFieldStatus]()

    @Published var selectedCountryOfBirth: Country?
    @Published private var dateOfBirthModel: StrigaUserDetailsResponse.DateOfBirth?
    @Published var phoneNumberModel: PhoneNumber?

    init(country: Country) {
        super.init()
        fetchSavedData()
        selectedCountryOfBirth = country

        actionPressed
            .sink { [weak self] _ in
                guard let self = self, let data = self.data else { return }
                self.isDataValid = isValid()
                if isValid() {
                    self.openNextStep.send(data)
                }
            }
            .store(in: &subscriptions)

        $isDataValid
            .map { $0 ? L10n.next : L10n.checkRedFields }
            .assignWeak(to: \.actionTitle, on: self)
            .store(in: &subscriptions)

        $dateOfBirth
            .map { $0.split(separator: ".") }
            .map { components in
                if components.count == Constants.dateFormat.split(separator: ".").count {
                    return StrigaUserDetailsResponse.DateOfBirth(year: Int(components[2]), month: Int(components[1]), day: Int(components[0]))
                }
                return nil
            }
            .assignWeak(to: \.dateOfBirthModel, on: self)
            .store(in: &subscriptions)

        $selectedCountryOfBirth
            .map { value in
                if let value {
                    return [value.emoji, value.name].compactMap { $0 } .joined(separator: " ")
                }
                return ""
            }
            .assignWeak(to: \.countryOfBirth, on: self)
            .store(in: &subscriptions)

        bindToFieldValues()
    }
}

private extension StrigaRegistrationFirstStepViewModel {
    func fetchSavedData() {
        // Mark as isLoading
        isLoading = true

        Task {
            do {
                guard let data = try await service.getRegistrationData() as? StrigaUserDetailsResponse
                else {
                    throw StrigaProviderError.invalidResponse
                }

                await MainActor.run {
                    // save data
                    self.data = data
                    isLoading = false
                    email = data.email
                    phoneNumber = data.mobile.number
                    firstName = data.firstName
                    surname = data.lastName
                    dateOfBirthModel = data.dateOfBirth
                    dateOfBirth = [data.dateOfBirth?.day, data.dateOfBirth?.month, data.dateOfBirth?.year]
                        .compactMap { String($0 ?? 0) }
                        .filter({ $0 != "0" })
                        .map {
                            if $0.count == 1 {
                                return "0\($0)"
                            }
                            return $0
                        }
                        .joined(separator: ".")
                }
            } catch {
                // TODO: - Handle error

                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    func isValid() -> Bool {
        validatePhone()
        validate(credential: firstName, field: .firstName)
        validate(credential: surname, field: .surname)
        validateDate()
        if countryOfBirth.isEmpty {
            fieldsStatuses[.countryOfBirth] = .invalid(error: L10n.couldNotBeEmpty)
        }
        return !fieldsStatuses.contains(where: { $0.value != .valid })
    }

    func validatePhone() {
        if phoneNumber.isEmpty {
            fieldsStatuses[.phoneNumber] = .invalid(error: L10n.couldNotBeEmpty)
        } else if phoneNumberModel != nil {
            fieldsStatuses[.phoneNumber] = .valid
        } else {
            fieldsStatuses[.phoneNumber] = .invalid(error: L10n.incorrectNumber)
        }
    }

    func validate(credential: String, field: Field) {
        if credential.isEmpty {
            fieldsStatuses[field] = .invalid(error: L10n.couldNotBeEmpty)
        } else {
            fieldsStatuses[field] = .valid
        }
    }

    func validateDate() {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: dateOfBirthModel?.year, month: dateOfBirthModel?.month, day: dateOfBirthModel?.day)
        if dateOfBirth.isEmpty {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.couldNotBeEmpty)
        } else if dateOfBirthModel?.year ?? 0 > 2015 {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.couldNotBeLater(2015))
        } else if dateOfBirthModel?.year ?? 0 < 1920 {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.couldNotBeEarlier(1920))
        } else if dateOfBirthModel?.month ?? 0 > 12 {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.incorrectMonth)
        } else if !components.isValidDate(in: calendar) {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.incorrectDay)
        } else {
            fieldsStatuses[.dateOfBirth] = .valid
        }
    }

    func bindToFieldValues() {
        let contacts = Publishers.CombineLatest($email, $phoneNumber)
        let credentials = Publishers.CombineLatest($firstName, $surname)
        let dateOfBirth = Publishers.CombineLatest($dateOfBirthModel, $selectedCountryOfBirth)
        Publishers.CombineLatest3(contacts, credentials, dateOfBirth)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] contacts, credentials, dateOfBirth in
                guard let self else { return }

                let mobile: StrigaUserDetailsResponse.Mobile
                if let phoneNumberModel = self.phoneNumberModel {
                    mobile = StrigaUserDetailsResponse.Mobile(
                        countryCode: "\(phoneNumberModel.countryCode)",
                        number: phoneNumberModel.numberString
                    )
                } else {
                    mobile = StrigaUserDetailsResponse.Mobile(countryCode: "", number: "")
                }

                let currentData: StrigaUserDetailsResponse = (try? await service.getRegistrationData() as? StrigaUserDetailsResponse) ?? .empty
                let newData = currentData.updated(
                    firstName: credentials.0,
                    lastName: credentials.1,
                    mobile: mobile,
                    dateOfBirth: dateOfBirth.0,
                    placeOfBirth: dateOfBirth.1?.code
                )
                try? await self.service.updateLocally(data: newData)

                if self.isDataValid == false {
                    self.isDataValid = self.isValid()
                }
            }
            .store(in: &subscriptions)
    }
}

private extension StrigaRegistrationFirstStepViewModel {
    enum Constants {
        static let dateFormat = "dd.mm.yyyy"
    }
}
