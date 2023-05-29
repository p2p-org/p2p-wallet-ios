import Foundation
import Combine
import SolanaSwift
import TweetNacl

public final class StrigaBankTransferUserDataRepository: BankTransferUserDataRepository {

    // MARK: - Properties

    private let localProvider: StrigaBankTransferLocalProvider
    private let remoteProvider: StrigaRemoteProvider

    // MARK: - Initializer

    public init(
        remoteProvider: StrigaRemoteProvider
    ) {
        localProvider = StrigaBankTransferLocalProvider()
        self.remoteProvider = remoteProvider
    }
    
    // MARK: - Methods
    public func createUser(registrationData data: RegistrationData) async throws -> StrigaCreateUserResponse {
        // assert response type
        guard let data = data as? StrigaUserDetailsResponse else {
            throw StrigaProviderError.invalidRequest("Data mismatch")
        }
        
        // create model
        let model = StrigaCreateUserRequest(
            firstName: data.firstName,
            lastName: data.lastName,
            email: data.email,
            mobile: StrigaCreateUserRequest.Mobile(countryCode: data.mobile.countryCode, number: data.mobile.number),
            dateOfBirth: StrigaCreateUserRequest.DateOfBirth(year: data.dateOfBirth?.year, month: data.dateOfBirth?.month, day: data.dateOfBirth?.day),
            address: StrigaCreateUserRequest.Address(
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
        do {
            let response = try await remoteProvider.createUser(model: model)
            debugPrint("---response: ", response)
            return response
        } catch {
            debugPrint("---error: ", error)
            throw error
        }
    }

    public func updateUser(registrationData data: RegistrationData) async throws {
        // assert response type
        guard let data = data as? StrigaUserDetailsResponse else {
            throw StrigaProviderError.invalidRequest("Data mismatch")
        }
        
        try? await localProvider.save(registrationData: data)
    }

    public func getRegistrationData() async throws -> RegistrationData {
        // TODO: Here should be email from metadata
        return await localProvider.getCachedRegistrationData() ?? StrigaUserDetailsResponse(firstName: "", lastName: "", email: "test@test.test", mobile: StrigaUserDetailsResponse.Mobile(countryCode: "", number: ""))
    }

    public func clearCache() async {
        await localProvider.clearRegistrationData()
    }
}

// MARK: - Helpers

private extension String {
    static let expectedIncomingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let expectedOutgoingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let purposeOfAccount = "CRYPTO_PAYMENTS"
}
