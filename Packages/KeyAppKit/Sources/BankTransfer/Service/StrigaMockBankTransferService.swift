import Combine
import Foundation

public final class StrigaMockBankTransferService: BankTransferService {

    public var userData: AnyPublisher<UserData, Never> { subject.eraseToAnyPublisher() }
    private let repository: BankTransferUserDataRepository

    let subject = CurrentValueSubject<UserData, Never>(
        UserData(countryCode: nil, userId: nil, mobileVerified: false)
    )

    public init() {
        repository = StrigaBankTransferUserDataRepository()
    }

    public func reload() async {
        let data = UserData(countryCode: "fr", userId: nil, mobileVerified: false)
        subject.send(data)
    }

    public func isBankTransferAvailable() -> Bool {
        return true
    }

    public func getRegistrationData() -> RegistrationData {
        repository.getRegistrationData()
    }

    public func save(data: RegistrationData) async throws {
        await repository.save(registrationData: data)
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

    public func clearCache() {
        fatalError("Not implemented")
    }
}
