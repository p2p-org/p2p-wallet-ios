import Foundation
import Combine
import SolanaSwift
import TweetNacl

public final class StrigaBankTransferUserDataRepository: BankTransferUserDataRepository {

    // MARK: - Properties

    private let localProvider: StrigaLocalProvider
    private let remoteProvider: StrigaRemoteProvider

    // MARK: - Initializer

    public init(
        localProvider: StrigaLocalProvider,
        remoteProvider: StrigaRemoteProvider
    ) {
        self.localProvider = localProvider
        self.remoteProvider = remoteProvider
    }
    
    // MARK: - Methods

    public func getUserId() async throws -> String? {
        // if local user id is available, return it
        if let localUserId = await localProvider.getUserId() {
            return localUserId
        }
        
        // otherwise retrieve from remote
        else {
            let userId = try await remoteProvider.getUserId()
            if let userId {
                // save to local
                await localProvider.saveUserId(userId)
            }
            return userId
        }
    }
    
    public func getKYCStatus() async throws -> StrigaKYC {
        try await remoteProvider.getKYCStatus()
    }
    
    public func isMobileVerified() async throws -> Bool {
        try await remoteProvider.isMobileVerified()
    }

    public func createUser(registrationData data: BankTransferRegistrationData) async throws -> StrigaCreateUserResponse {
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
            try await localProvider.save(registrationData: data)
            await localProvider.saveUserId(response.userId)
            return response
        } catch {
            throw error
        }
    }

    public func updateUserLocally(registrationData data: BankTransferRegistrationData) async throws {
        // assert response type
        guard let data = data as? StrigaUserDetailsResponse else {
            throw StrigaProviderError.invalidRequest("Data mismatch")
        }
        try? await localProvider.save(registrationData: data)
    }
    
    public func updateUser(registrationData data: BankTransferRegistrationData) async throws {
        // TODO: - remoteProvider.updateUser
        fatalError("Implementing")
    }
    
    public func verifyMobileNumber(userId: String, verificationCode code: String) async throws {
        try await remoteProvider.verifyMobileNumber(userId: userId, verificationCode: code)
    }
    
    public func resendSMS(userId: String) async throws {
        try await remoteProvider.resendSMS(userId: userId)
    }
    
    public func getKYCToken(userId: String) async throws -> String {
        try await remoteProvider.getKYCToken(userId: userId)
    }

    public func getRegistrationData() async throws -> BankTransferRegistrationData {
        if let cachedData = await localProvider.getCachedRegistrationData()
        {
            if let userId = try await getUserId(),
               let response = try? await remoteProvider.getUserDetails(userId: userId)
            {
                // save to local provider
                try await localProvider.save(registrationData: response)
                
                // return
                return response
            }
            
            // if not response cached data
            return cachedData
        }
        
        // return empty data
        return StrigaUserDetailsResponse(
            firstName: "",
            lastName: "",
            email: "",
            mobile: .init(
                countryCode: "",
                number: ""
            ),
            KYC: .notStarted
        )
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
