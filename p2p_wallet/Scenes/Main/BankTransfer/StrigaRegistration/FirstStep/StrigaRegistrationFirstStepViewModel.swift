import Combine
import BankTransfer
import Resolver
import CountriesAPI

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

    // Fields
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var firstName: String = ""
    @Published var surname: String = ""
    @Published var dateOfBirth: String = ""
    @Published var countryOfBirth: String = ""

    // Other views
    @Published var actionTitle: String = L10n.next
    @Published var isDataValid = true
    let actionPressed = PassthroughSubject<Void, Never>()
    let openNextStep = PassthroughSubject<Void, Never>()
    let chooseCountry = PassthroughSubject<Country?, Never>()

    var fieldsStatuses = [Field: StrigaRegistrationTextFieldStatus]()

    @Published var selectedCountryOfBirth: Country?
    @Published private var dateOfBirthModel: RegistrationData.DateOfBirth?
    private let dateFormat = "dd.mm.yyyy"

    init(country: Country) {
        super.init()
        let data = service.getRegistrationData()
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
        selectedCountryOfBirth = country

        actionPressed
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isDataValid = isValid()
                if isValid() {
                    self.openNextStep.send(())
                } else {
                    self.actionTitle = L10n.checkRedFields
                }
            }
            .store(in: &subscriptions)

        $phoneNumber
            .sink { [weak self] value in
                guard let self else { return }
                if !value.isEmpty {
                    self.fieldsStatuses[.phoneNumber] = .valid
                }
            }
            .store(in: &subscriptions)

        $firstName
            .sink { [weak self] value in
                guard let self else { return }
                if !value.isEmpty {
                    self.fieldsStatuses[.firstName] = .valid
                }
            }
            .store(in: &subscriptions)

        $surname
            .sink { [weak self] value in
                guard let self else { return }
                if !value.isEmpty {
                    self.fieldsStatuses[.surname] = .valid
                }
            }
            .store(in: &subscriptions)

        $dateOfBirth
            .sink { [weak self] value in
                guard let self else { return }
                if !value.isEmpty {
                    self.fieldsStatuses[.dateOfBirth] = .valid
                }
            }
            .store(in: &subscriptions)

        $dateOfBirth
            .map { $0.split(separator: ".") }
            .map { [weak self] components in
                if components.count == self?.dateFormat.split(separator: ".").count {
                    return RegistrationData.DateOfBirth(year: Int(components[2]), month: Int(components[1]), day: Int(components[0]))
                } else {
                    return nil
                }
            }
            .assignWeak(to: \.dateOfBirthModel, on: self)
            .store(in: &subscriptions)

        $selectedCountryOfBirth
            .map { value in
                if let value {
                    return [value.emoji, value.name].compactMap { $0 } .joined(separator: " ")
                } else {
                    return ""
                }
            }
            .assignWeak(to: \.countryOfBirth, on: self)
            .store(in: &subscriptions)

        bindSave()
    }
}

private extension StrigaRegistrationFirstStepViewModel {
    func isValid() -> Bool {
        if phoneNumber.isEmpty {
            fieldsStatuses[.phoneNumber] = .invalid(error: L10n.couldNotBeEmpty)
        }
        validate(credential: firstName, field: .firstName)
        validate(credential: surname, field: .surname)
        validateDate()
        if countryOfBirth.isEmpty {
            fieldsStatuses[.countryOfBirth] = .invalid(error: L10n.couldNotBeEmpty)
        }
        return !fieldsStatuses.contains(where: { $0.value != .valid })
    }

    func validate(credential: String, field: Field) {
        if credential.isEmpty {
            fieldsStatuses[field] = .invalid(error: L10n.couldNotBeEmpty)
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
        }
    }

    func bindSave() {
        let contacts = Publishers.CombineLatest($email, $phoneNumber)
        let credentials = Publishers.CombineLatest($firstName, $surname)
        let dateOfBirth = Publishers.CombineLatest($dateOfBirthModel, $selectedCountryOfBirth)
        Publishers.CombineLatest3(contacts, credentials, dateOfBirth)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] contacts, credentials, dateOfBirth in
                guard let self else { return }
                try? await self.service.save(data: RegistrationData(
                    firstName: credentials.0,
                    lastName: credentials.1,
                    email: contacts.0,
                    mobile: RegistrationData.Mobile(countryCode: "", number: contacts.1),
                    dateOfBirth: dateOfBirth.0,
                    placeOfBirth: dateOfBirth.1?.code
                ))
            }
            .store(in: &subscriptions)
    }
}
