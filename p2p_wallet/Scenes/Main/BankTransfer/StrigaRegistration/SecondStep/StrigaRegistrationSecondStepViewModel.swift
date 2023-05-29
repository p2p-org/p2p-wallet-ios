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
    let openSelectOccupationIndustry = PassthroughSubject<Void, Never>()

    var fieldsStatuses = [Field: StrigaRegistrationTextFieldStatus]()

    @Published var selectedCountry: Country?

    init(data: StrigaUserDetailsResponse) {
        super.init()
        
        occupationIndustry = data.occupation ?? ""
        sourceOfFunds = data.sourceOfFunds ?? ""
        country = data.address?.country ?? ""
        city = data.address?.city ?? ""
        addressLine = data.address?.addressLine1 ?? ""
        postalCode = data.address?.postalCode ?? ""
        stateRegion = data.address?.state ?? ""

        actionPressed
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isDataValid = isValid()
                if isValid() {
                    self.openNextStep.send(())
                }
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
                } else {
                    return ""
                }
            }
            .assignWeak(to: \.country, on: self)
            .store(in: &subscriptions)

        bindToFieldValues()
    }
}

private extension StrigaRegistrationSecondStepViewModel {

    func isValid() -> Bool {
        return !fieldsStatuses.contains(where: { $0.value != .valid })
    }

    func bindToFieldValues() {
        let sourceOfFunds = Publishers.CombineLatest($occupationIndustry, $sourceOfFunds)
        let address1 = Publishers.CombineLatest($country, $city)
        let address2 = Publishers.CombineLatest3($addressLine, $postalCode, $stateRegion)
        Publishers.CombineLatest3(sourceOfFunds, address1, address2)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sinkAsync { [weak self] contacts, credentials, dateOfBirth in
                guard let self else { return }

                // TODO: Save registration data

                if self.isDataValid == false {
                    self.isDataValid = self.isValid()
                }
            }
            .store(in: &subscriptions)
    }
}
