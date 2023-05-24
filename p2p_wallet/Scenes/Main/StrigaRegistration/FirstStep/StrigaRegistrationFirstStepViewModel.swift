import Combine
import BankTransfer
import Resolver

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
    let chooseCountry = PassthroughSubject<String, Never>()

    var fieldsStatuses = [Field: StrigaRegistrationTextFieldStatus]()

    init(country: String) {
        super.init()
        let data = service.getRegistrationData()
        email = data.email
        phoneNumber = data.mobile.number
        firstName = data.firstName
        surname = data.lastName
        dateOfBirth = [data.dateOfBirth?.day, data.dateOfBirth?.month, data.dateOfBirth?.year]
            .compactMap { String($0 ?? 0) }
            .joined()
        countryOfBirth = country

        actionPressed
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isDataValid = isValid()
                if isValid() {
                    self.openNextStep.send(())
                } else {
                    self.actionTitle = L10n.fillYourData
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
                    self.fieldsStatuses[.phoneNumber] = .valid
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

        // TODO: Do country of birth

        bindSave()
    }
}

private extension StrigaRegistrationFirstStepViewModel {
    func isValid() -> Bool {
        if phoneNumber.isEmpty {
            fieldsStatuses[.phoneNumber] = .invalid(error: L10n.couldNotBeEmpty)
        }
        if firstName.isEmpty {
            fieldsStatuses[.firstName] = .invalid(error: L10n.couldNotBeEmpty)
        }
        if surname.isEmpty {
            fieldsStatuses[.surname] = .invalid(error: L10n.couldNotBeEmpty)
        }
        if dateOfBirth.isEmpty {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.couldNotBeEmpty)
        }
        if countryOfBirth.isEmpty {
            fieldsStatuses[.countryOfBirth] = .invalid(error: L10n.couldNotBeEmpty)
        }
        return !fieldsStatuses.contains(where: { $0.value != .valid })
    }

    func bindSave() {
        let contacts = Publishers.CombineLatest($email, $phoneNumber)
        let credentials = Publishers.CombineLatest($firstName, $surname)
        let dateOfBirth = Publishers.CombineLatest($dateOfBirth, $countryOfBirth)
        Publishers.CombineLatest3(contacts, credentials, dateOfBirth)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] contacts, credentials, dateOfBirth in
                guard let self else { return }
                try? await self.service.save(data: RegistrationData(
                    firstName: credentials.0,
                    lastName: credentials.1,
                    email: contacts.0,
                    mobile: RegistrationData.Mobile(countryCode: "", number: contacts.1)
                ))
            }
            .store(in: &subscriptions)
    }
}
