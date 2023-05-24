import Combine

final class StrigaBankTransferUserDataRepository: BankTransferUserDataRepository {

    var userData: UserData?

    private let provider: StrigaBankTransferProvider

    init() {
        provider = StrigaBankTransferLocalProvider()
    }

    func reload() async {
        fatalError("Not implemented")
    }

    func save(userData: UserData) async {
        fatalError("Not implemented")
    }

    func save(registrationData: RegistrationData) async {
        try? provider.save(registrationData: registrationData)
    }

    func getRegistrationData() -> RegistrationData {
        // TODO: Here should be email from metadata
        return provider.getCachedRegistrationData() ?? RegistrationData(firstName: "", lastName: "", email: "test@test.test", mobile: RegistrationData.Mobile(countryCode: "", number: ""))
    }

    func clearCache() {
        provider.clearRegistrationData()
    }
}
