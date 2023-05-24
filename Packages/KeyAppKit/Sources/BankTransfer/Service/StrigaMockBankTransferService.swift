import Combine
import Foundation

public final class StrigaMockBankTransferService: BankTransferService {

    public var userData: AnyPublisher<UserData, Never> { subject.eraseToAnyPublisher() }

    let subject = CurrentValueSubject<UserData, Never>(
        UserData(countryCode: nil, userId: nil, mobileVerified: false)
    )

    public init() { }

    public func reload() async {
        let data = UserData(countryCode: "fr", userId: nil, mobileVerified: false)
        subject.send(data)
    }

    public func isBankTransferAvailable() -> Bool {
        return true
    }

    public func getRegistrationData() async -> RegistrationData {
        return RegistrationData(
            firstName: "test@test.test",
            lastName: "",
            email: "",
            phoneCountryCode: "",
            phoneNumber: "",
            dateOfBirth: nil,
            placeOfBirth: nil,
            occupation: nil,
            placeOfLive: nil
        )
    }

    public func createUser(data: RegistrationData) async throws {
        throw NSError()
    }

    public func getOTP() async throws {
        throw NSError()
    }

    public func verify(OTP: String) async throws -> Bool {
        throw NSError()
    }
}
