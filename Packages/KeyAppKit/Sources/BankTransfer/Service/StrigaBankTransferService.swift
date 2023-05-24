import Combine
import Foundation

private extension String {
    static let expectedIncomingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let expectedOutgoingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let purposeOfAccount = "CRYPTO_PAYMENTS"
}

public final class StrigaBankTransferService {

    // Dependencies
    private let strigaProvider: IStrigaProvider
    private let repository: BankTransferUserDataRepository

    // Subjects
    let subject = CurrentValueSubject<UserData, Never>(
        UserData(countryCode: nil, userId: nil, mobileVerified: false)
    )

    // MARK: - Init

    public init(strigaProvider: IStrigaProvider) {
        self.strigaProvider = strigaProvider
        self.repository = StrigaBankTransferUserDataRepository()
    }
}

// MARK: - BankTransferService

extension StrigaBankTransferService: BankTransferService {

    public var userData: AnyPublisher<UserData, Never> { subject.eraseToAnyPublisher() }

    public func reload() async {
        fatalError("Not implemented")
    }

    public func isBankTransferAvailable() -> Bool {
        fatalError("Not implemented")
    }

    public func getRegistrationData() -> RegistrationData {
        repository.getRegistrationData()
    }

    public func save(data: RegistrationData) async throws {
        await repository.save(registrationData: data)
    }

    public func createUser(data: RegistrationData) async throws {
        let model = CreateUserRequest(
            firstName: data.firstName,
            lastName: data.lastName,
            email: data.email,
            mobile: CreateUserRequest.Mobile(countryCode: data.mobile.countryCode, number: data.mobile.number),
            dateOfBirth: CreateUserRequest.DateOfBirth(year: data.dateOfBirth?.year, month: data.dateOfBirth?.month, day: data.dateOfBirth?.day),
            address: CreateUserRequest.Address(
                addressLine1: data.address?.addressLine1,
                addressLine2: data.address?.addressLine2,
                city: data.address?.city,
                postalCode: data.address?.postalCode,
                state: data.address?.state,
                country: data.address?.country
            ),
            occupation: data.occupation,
            sourceOfFunds: data.sourceOfFunds,
            ipAddress: nil,
            placeOfBirth: data.placeOfBirth,
            expectedIncomingTxVolumeYearly: .expectedIncomingTxVolumeYearly,
            expectedOutgoingTxVolumeYearly: .expectedOutgoingTxVolumeYearly,
            selfPepDeclaration: false,
            purposeOfAccount: .purposeOfAccount
        )
        Task {
            do {
                let response = try await strigaProvider.createUser(model: model)
                debugPrint("---response: ", response)
            } catch {
                debugPrint("---error: ", error)
            }
        }
    }

    public func getOTP() async throws {
        fatalError("Not implemented")
    }

    public func verify(OTP: String) async throws -> Bool {
        fatalError("Not implemented")
    }

    public func clearCache() {
        repository.clearCache()
    }
}
