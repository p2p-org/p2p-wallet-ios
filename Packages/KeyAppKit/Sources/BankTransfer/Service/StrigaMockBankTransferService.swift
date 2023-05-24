import Combine
import Foundation

public final class StrigaMockBankTransferService: BankTransferService {

    private var _userData: UserData = .init(countryCode: "fr", userId: nil, mobileVerified: false)

    public var userData: AnyPublisher<UserData, Never> { subject.eraseToAnyPublisher() }

    let subject = CurrentValueSubject<UserData, Never>(
        UserData(countryCode: nil, userId: nil, mobileVerified: false)
    )

    public init() { }

    public func reload() async {
        sleep(5)
        let data = _userData
        subject.send(data)
    }

    public func save(userData: UserData) throws {
        self._userData = userData
    }

    public func set(countryCode: String) throws {
        self._userData = UserData(
            countryCode: countryCode,
            userId: _userData.userId,
            mobileVerified: _userData.mobileVerified
        )
    }

    public func isBankTransferAvailable() -> Bool {
        return false
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
