import Combine

final class StrigaBankTransferUserDataRepository: BankTransferUserDataRepository {

    var userData: UserData?

    private let provider: StrigaBankTransferLocalProvider

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
        try? await provider.save(registrationData: registrationData)
    }

    func getRegistrationData() async -> RegistrationData {
        // TODO: Here should be email from metadata
        return await provider.getCachedRegistrationData() ?? RegistrationData(firstName: "", lastName: "", email: "test@test.test", mobile: RegistrationData.Mobile(countryCode: "", number: ""))
    }

    func clearCache() async {
        await provider.clearRegistrationData()
    }
}
