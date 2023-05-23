import Combine
import Foundation

public final class StrigaBankTransferService: BankTransferService {

    public var userData: AnyPublisher<UserData, Never> { subject.eraseToAnyPublisher() }

    let subject = CurrentValueSubject<UserData, Never>(
        UserData(countryCode: nil, userId: nil, mobileVerified: false)
    )

    public func reload() async {
        fatalError("Not implemented")
    }

    public func isBankTransferAvailable() -> Bool {
        fatalError("Not implemented")
    }

    public func getRegistrationData() async -> RegistrationData {
        fatalError("Not implemented")

    }

    public func save(regData: RegistrationData) async throws {
        fatalError("Not implemented")
    }

    public func getOTP() async throws {
        fatalError("Not implemented")
    }

    public func verify(OTP: String) async throws -> Bool {
        fatalError("Not implemented")
    }
}
