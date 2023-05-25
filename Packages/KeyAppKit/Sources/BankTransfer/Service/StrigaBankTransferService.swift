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
    
    // Subjects
    let subject = CurrentValueSubject<UserData, Never>(
        UserData(countryCode: nil, userId: nil, mobileVerified: false)
    )
    
    // MARK: - Init
    
    public init(strigaProvider: IStrigaProvider) {
        self.strigaProvider = strigaProvider
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

    public func getRegistrationData() async -> RegistrationData {
        fatalError("Not implemented")

    }

    public func createUser(data: RegistrationData) async throws {
        let model = CreateUserRequest(
            firstName: data.firstName,
            lastName: data.lastName,
            email: data.email,
            mobile: CreateUserRequest.Mobile(countryCode: data.phoneCountryCode, number: data.phoneNumber),
            dateOfBirth: nil,
            address: nil,
            occupation: data.occupation,
            sourceOfFunds: nil,
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
}
