import Combine
import BankTransfer
import Resolver
import CountriesAPI

final class StrigaRegistrationSecondStepViewModel: BaseViewModel, ObservableObject {

    enum Field {
        case occupationIndustry
        case sourceOfFunds
        case country
        case city
        case addressLine
        case postalCode
        case stateRegion
    }

    // Dependencies
    @Injected private var service: BankTransferService
    @Injected private var notificationService: NotificationService
    @Injected private var countriesService: CountriesAPI
    private let industryProvider: ChooseIndustryDataLocalProvider

    @Published var isLoading = false
    // Fields
    @Published var occupationIndustry: String = ""
    @Published var sourceOfFunds: String = ""
    @Published var country: String = ""
    @Published var city: String = ""
    @Published var addressLine: String = ""
    @Published var postalCode: String = ""
    @Published var stateRegion: String = ""

    // Other views
    @Published var actionTitle: String = L10n.confirm
    @Published var isDataValid = true // We need this flag to allow user enter at first whatever he/she likes and then validate everything
    let actionPressed = PassthroughSubject<Void, Never>()
    let openNextStep = PassthroughSubject<Void, Never>()
    let chooseIndustry = PassthroughSubject<Industry?, Never>()
    let chooseSourceOfFunds = PassthroughSubject<StrigaSourceOfFunds?, Never>()
    let chooseCountry = PassthroughSubject<Country?, Never>()

    var fieldsStatuses = [Field: StrigaRegistrationTextFieldStatus]()

    @Published var selectedCountry: Country?
    @Published var selectedIndustry: Industry?
    @Published var selectedSourceOfFunds: StrigaSourceOfFunds?

    init(data: StrigaUserDetailsResponse) {
        industryProvider = ChooseIndustryDataLocalProvider()
        super.init()
        setInitial(userData: data)

        actionPressed
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isDataValid = isValid()
                guard isValid() else { return }
                self.createUser()
            }
            .store(in: &subscriptions)

        $isDataValid
            .map { $0 ? L10n.confirm : L10n.checkRedFields }
            .assignWeak(to: \.actionTitle, on: self)
            .store(in: &subscriptions)

        $selectedCountry
            .map { value in
                if let value {
                    return [value.emoji, value.name].compactMap { $0 } .joined(separator: " ")
                }
                return ""
            }
            .assignWeak(to: \.country, on: self)
            .store(in: &subscriptions)

        $selectedIndustry
            .map { $0?.wholeName ?? "" }
            .assignWeak(to: \.occupationIndustry, on: self)
            .store(in: &subscriptions)

        $selectedSourceOfFunds
            .map { $0?.title ?? "" }
            .assignWeak(to: \.sourceOfFunds, on: self)
            .store(in: &subscriptions)

        bindToFieldValues()
    }
}

private extension StrigaRegistrationSecondStepViewModel {

    func setInitial(userData: StrigaUserDetailsResponse) {
        if let industry = userData.occupation {
            selectedIndustry = industryProvider.getIndustries().first(where: { $0.rawValue == industry })
        }

        selectedSourceOfFunds = userData.sourceOfFunds
        city = userData.address?.city ?? ""
        addressLine = userData.address?.addressLine1 ?? ""
        postalCode = userData.address?.postalCode ?? ""
        stateRegion = userData.address?.state ?? ""

        Task {
            let countries = try await self.countriesService.fetchCountries()
            if let country = countries.first(where: {
                $0.code.lowercased() == userData.address?.country?.lowercased() ?? userData.placeOfBirth?.lowercased()
            }) {
                self.selectedCountry = country
            }
        }
    }

    func isValid() -> Bool {
        validate(value: city, field: .city, minLimit: 2, maxLimit: 40)
        validate(value: addressLine, field: .addressLine, maxLimit: 160)
        validate(value: postalCode, field: .postalCode, maxLimit: 20)
        validate(value: country, field: .country)
        validate(value: occupationIndustry, field: .occupationIndustry)
        validate(value: sourceOfFunds, field: .sourceOfFunds)
        return !fieldsStatuses.contains(where: { $0.value != .valid })
    }

    func validate(value: String, field: Field, minLimit: Int? = nil, maxLimit: Int? = nil) {
        if value.isEmpty {
            fieldsStatuses[field] = .invalid(error: L10n.couldNotBeEmpty)
        } else if let minLimit, value.count < minLimit {
            fieldsStatuses[field] = .invalid(error: L10n.couldNotBeLessThanSymbols(minLimit))
        } else if let maxLimit, value.count > maxLimit {
            fieldsStatuses[field] = .invalid(error: L10n.couldNotBeMoreThanSymbols(maxLimit))
        } else {
            fieldsStatuses[field] = .valid
        }
    }

    func bindToFieldValues() {
        let sourceOfFunds = Publishers.CombineLatest($selectedIndustry, $selectedSourceOfFunds)
        let address1 = Publishers.CombineLatest($selectedCountry, $city)
        let address2 = Publishers.CombineLatest3($addressLine, $postalCode, $stateRegion)
        Publishers.CombineLatest3(sourceOfFunds, address1, address2)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] sourceOfFunds, address1, address2 in
                guard let self else { return }

                let currentData: StrigaUserDetailsResponse = (try? await service.getRegistrationData() as? StrigaUserDetailsResponse) ?? .empty

                let newData = currentData.updated(
                    address: StrigaUserDetailsResponse.Address(
                        addressLine1: address2.0,
                        addressLine2: nil,
                        city: address1.1,
                        postalCode: address2.1,
                        state: address2.2.isEmpty ? nil : address2.2,
                        country: address1.0?.code
                    ),
                    occupation: .some(sourceOfFunds.0?.rawValue),
                    sourceOfFunds: .some(sourceOfFunds.1)
                )

                try? await self.service.updateLocally(data: newData)

                if self.isDataValid == false {
                    self.isDataValid = self.isValid()
                }
            }
            .store(in: &subscriptions)
    }

    func createUser() {
        isLoading = true
        Task {
            do {
                // get registration data
                guard let currentData = try await service.getRegistrationData() as? StrigaUserDetailsResponse else { throw NSError() }

                // create user
                try await service.createUser(data: currentData)
                await MainActor.run {
                    self.isLoading = false
                }
                self.openNextStep.send(())
            } catch {
                self.notificationService.showDefaultErrorNotification()
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
