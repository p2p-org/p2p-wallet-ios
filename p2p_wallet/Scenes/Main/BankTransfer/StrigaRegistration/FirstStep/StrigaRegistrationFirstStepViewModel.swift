import Combine
import BankTransfer
import Resolver
import CountriesAPI
import PhoneNumberKit
import Foundation
import Onboarding

final class StrigaRegistrationFirstStepViewModel: BaseViewModel, ObservableObject {

    // Dependencies
    @Injected private var service: any BankTransferService
    @Injected private var countriesService: CountriesAPI
    @Injected private var strigaMetadata: StrigaMetadataProvider
    private let phoneNumberKit = PhoneNumberKit()

    // Data
    private var data: StrigaUserDetailsResponse?
    
    // Loading state
    @Published var isLoading = false

    // Fields
    @Published var email: String = ""
    @Published var firstName: String = ""
    @Published var surname: String = ""
    @Published var dateOfBirth: String = ""
    @Published var countryOfBirth: String = ""
    // PhoneTextField
    @Published var phoneNumber: String = ""
    @Published var selectedPhoneCountryCode: Country?
    @Published var phoneNumberModel: PhoneNumber?

    // Other views
    @Published var actionTitle: String = L10n.next
    @Published var isDataValid = true // We need this flag to allow user enter at first whatever he/she likes and then validate everything
    let actionPressed = PassthroughSubject<Void, Never>()
    let openNextStep = PassthroughSubject<StrigaUserDetailsResponse, Never>()
    let chooseCountry = PassthroughSubject<Country?, Never>()
    let choosePhoneCountryCode = PassthroughSubject<Country?, Never>()
    let back = PassthroughSubject<Void, Never>()

    var fieldsStatuses = [StrigaRegistrationField: StrigaRegistrationTextFieldStatus]()

    @Published var selectedCountryOfBirth: Country?
    @Published private var dateOfBirthModel: StrigaUserDetailsResponse.DateOfBirth?

    private lazy var birthMaxYear: Int = {
        Date().year - Constants.maxYearGap
    }()

    private lazy var birthMinYear: Int = {
        Date().year - Constants.minYearGap
    }()

    private let preselectedCountry: Country

    init(country: Country) {
        preselectedCountry = country
        super.init()
        fetchSavedData()

        actionPressed
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isDataValid = isValid()
                if isValid(), let data = self.data {
                    self.openNextStep.send(data)
                }
            }
            .store(in: &subscriptions)

        $isDataValid
            .map { $0 ? L10n.next : L10n.checkRedFields }
            .assignWeak(to: \.actionTitle, on: self)
            .store(in: &subscriptions)

        $dateOfBirth
            .map { $0.split(separator: ".").map { String($0) } }
            .map { components in
                if components.count == Constants.dateFormat.split(separator: ".").count {
                    return StrigaUserDetailsResponse.DateOfBirth(year: components[2], month: components[1], day: components[0])
                }
                return nil
            }
            .assignWeak(to: \.dateOfBirthModel, on: self)
            .store(in: &subscriptions)

        $selectedCountryOfBirth
            .map { model in
                if let model {
                    return [model.emoji, model.name].compactMap { $0 } .joined(separator: " ")
                } else {
                    return ""
                }
            }
            .assignWeak(to: \.countryOfBirth, on: self)
            .store(in: &subscriptions)

        $selectedPhoneCountryCode
            .map { [weak self] value in
                guard let self, let value else { return nil }
                let number = try? self.phoneNumberKit.parse("\(value.dialCode)\(phoneNumber)")
                return number
            }
            .assignWeak(to: \.phoneNumberModel, on: self)
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

                if let countries = try? await self.countriesService.fetchCountries() {
                    await fetchSaved(placeOfBirth: data.placeOfBirth, countries: countries)
                    await fetchPhoneNumber(data: data, countries: countries)
                }

                await MainActor.run {
                    // save data
                    self.data = data
                    isLoading = false
                    email = data.email
                    firstName = data.firstName
                    surname = data.lastName
                    dateOfBirthModel = data.dateOfBirth
                    dateOfBirth = [data.dateOfBirth?.day, data.dateOfBirth?.month, data.dateOfBirth?.year]
                        .compactMap { $0 }
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
                self.data = StrigaUserDetailsResponse.empty
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    func fetchSaved(placeOfBirth: String?, countries: Countries) async {
        if let country = countries.first(where: {
            $0.alpha3Code.lowercased() == placeOfBirth?.lowercased()
        }) {
            await MainActor.run {
                self.selectedCountryOfBirth = country
            }
        }
    }

    func fetchPhoneNumber(data: StrigaUserDetailsResponse, countries: Countries) async {
        let metadataService: WalletMetadataService = Resolver.resolve()
        // Web3 phone by default
        var metaPhoneNumber: String = metadataService.metadata.value?.phoneNumber ?? ""
        // Use a phone from the local state if we have one
        if !data.mobile.isEmpty, let dataMobileNumber = data.mobileNumber {
            metaPhoneNumber = dataMobileNumber
        } else if data.mobile.isEmpty, let strigaPhoneNumber = await self.strigaMetadata.getStrigaMetadata()?.phoneNumber {
            metaPhoneNumber = strigaPhoneNumber
        }
        await MainActor.run {
            phoneNumber = metaPhoneNumber
            if let number = try? phoneNumberKit.parse(phoneNumber) {
                phoneNumberModel = number
                selectedPhoneCountryCode = countries.first(where: {
                    if let regionId = number.regionID {
                        return $0.code.lowercased() == regionId.lowercased()
                    } else {
                        return $0.dialCode == "+\(number.countryCode)"
                    }
                })
                phoneNumber = phoneNumberKit.format(number, toType: .international, withPrefix: false)
                    .replacingOccurrences(of: "-", with: "")
            } else {
                selectedPhoneCountryCode = countries.first(where: { $0.dialCode == "\(data.mobile.countryCode)" })
                phoneNumber = data.mobile.number
            }
        }
    }

    func isValid() -> Bool {
        validatePhone()
        validate(credential: firstName, field: .firstName)
        validate(credential: surname, field: .surname)
        validatePlaceOfBirth()
        validateDate()
        if countryOfBirth.isEmpty {
            fieldsStatuses[.countryOfBirth] = .invalid(error: L10n.couldNotBeEmpty)
        }
        return !fieldsStatuses.contains(where: { $0.value != .valid })
    }

    func validatePlaceOfBirth() {
        if selectedCountryOfBirth == nil {
            fieldsStatuses[.countryOfBirth] = .invalid(error: L10n.couldNotBeEmpty)
        } else {
            fieldsStatuses[.countryOfBirth] = .valid
        }
    }

    func validatePhone() {
        if phoneNumber.isEmpty || selectedPhoneCountryCode == nil {
            fieldsStatuses[.phoneNumber] = .invalid(error: L10n.couldNotBeEmpty)
        } else if phoneNumberModel != nil {
            fieldsStatuses[.phoneNumber] = .valid
        } else {
            fieldsStatuses[.phoneNumber] = .invalid(error: L10n.incorrectNumber)
        }
    }

    func validate(credential: String, field: StrigaRegistrationField) {
        if credential.trimmed().isEmpty {
            fieldsStatuses[field] = .invalid(error: L10n.couldNotBeEmpty)
        } else if credential.count < Constants.minCredentialSymbols {
            fieldsStatuses[field] = .invalid(error: L10n.couldNotBeLessThanSymbols(Constants.minCredentialSymbols))
        } else if credential.count > Constants.maxCredentialSymbols {
            fieldsStatuses[field] = .invalid(error: L10n.couldNotBeMoreThanSymbols(Constants.maxCredentialSymbols))
        } else {
            fieldsStatuses[field] = .valid
        }
    }

    func validateDate() {
        let year = Int(dateOfBirthModel?.year ?? "") ?? 0
        let month = Int(dateOfBirthModel?.month ?? "") ?? 0
        let day = Int(dateOfBirthModel?.day ?? "") ?? 0
        let components = DateComponents(year: year, month: month, day: day)
        if dateOfBirth.isEmpty {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.couldNotBeEmpty)
        } else if year > birthMaxYear {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.couldNotBeLater(birthMaxYear))
        } else if year < birthMinYear {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.couldNotBeEarlier(birthMinYear))
        } else if month > 12 {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.incorrectMonth)
        } else if !components.isValidDate(in: Calendar.current) {
            fieldsStatuses[.dateOfBirth] = .invalid(error: L10n.incorrectDay)
        } else {
            fieldsStatuses[.dateOfBirth] = .valid
        }
    }

    func bindToFieldValues() {
        let contacts = Publishers.CombineLatest3($email, $selectedPhoneCountryCode, $phoneNumber)
        let credentials = Publishers.CombineLatest($firstName, $surname)
        let dateOfBirth = Publishers.CombineLatest($dateOfBirthModel, $selectedCountryOfBirth)
        Publishers.CombineLatest3(contacts, credentials, dateOfBirth)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] contacts, credentials, dateOfBirth in
                guard let self else { return }

                let mobile = StrigaUserDetailsResponse.Mobile(
                    countryCode: contacts.1?.dialCode ?? "",
                    number: contacts.2.replacingOccurrences(of: " ", with: "")
                )

                let currentData: StrigaUserDetailsResponse = (try? await service.getRegistrationData() as? StrigaUserDetailsResponse) ?? .empty
                let newData = currentData.updated(
                    firstName: credentials.0.trimmed(),
                    lastName: credentials.1.trimmed(),
                    mobile: mobile,
                    dateOfBirth: dateOfBirth.0,
                    address: StrigaUserDetailsResponse.Address(
                        addressLine1: currentData.address?.addressLine1,
                        addressLine2: currentData.address?.addressLine2,
                        city: currentData.address?.city,
                        postalCode: currentData.address?.postalCode,
                        state: currentData.address?.state,
                        country: preselectedCountry.code
                    ),
                    placeOfBirth: dateOfBirth.1?.alpha3Code
                )
                self.data = newData
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
        static let minYearGap = 103
        static let maxYearGap = 8
        static let minCredentialSymbols = 2
        static let maxCredentialSymbols = 40
    }
}

private extension Date {
    var year: Int {
        (Calendar.current.dateComponents([.year], from: self).year ?? 0)
    }
}

private extension String {
    func trimmed() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
