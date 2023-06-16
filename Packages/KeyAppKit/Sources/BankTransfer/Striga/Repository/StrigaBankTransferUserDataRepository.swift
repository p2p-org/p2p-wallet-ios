import Foundation
import Combine
import SolanaSwift
import TweetNacl

public final class StrigaBankTransferUserDataRepository: BankTransferUserDataRepository {

    // MARK: - Properties

    private let localProvider: StrigaLocalProvider
    private let remoteProvider: StrigaRemoteProvider
    private let metadataProvider: StrigaMetadataProvider

    // MARK: - Initializer

    public init(
        localProvider: StrigaLocalProvider,
        remoteProvider: StrigaRemoteProvider,
        metadataProvider: StrigaMetadataProvider
    ) {
        self.localProvider = localProvider
        self.remoteProvider = remoteProvider
        self.metadataProvider = metadataProvider
    }
    
    // MARK: - Methods
    public func synchronizeMetadata() async {
        await metadataProvider.synchronize()
    }

    public func getUserId() async -> String? {
        await metadataProvider.getLocalStrigaMetadata()?.userId
    }
    
    public func getKYCStatus() async throws -> StrigaKYC {
        guard let userId = await getUserId() else {
            throw BankTransferError.missingUserId
        }
        return try await remoteProvider.getKYCStatus(userId: userId)
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
            mobile: StrigaCreateUserRequest.Mobile(
                countryCode: data.mobile.countryCode,
                number: data.mobile.number
            ),
            dateOfBirth: StrigaCreateUserRequest.DateOfBirth(
                year: data.dateOfBirth?.year,
                month: data.dateOfBirth?.month,
                day: data.dateOfBirth?.day
            ),
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
        // send createUser
        let response = try await remoteProvider.createUser(model: model)
        
        // save registration data
        try await localProvider.save(registrationData: data)
        
        // save userId
        try await metadataProvider.updateMetadata(withUserId: response.userId)
        
        // synchronize
        await synchronizeMetadata()
        
        // return
        return response
    }

    public func updateUserLocally(registrationData data: BankTransferRegistrationData) async throws {
        // assert response type
        guard let data = data as? StrigaUserDetailsResponse else {
            throw StrigaProviderError.invalidRequest("Data mismatch")
        }
        try? await localProvider.save(registrationData: data)
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
        // get metadata
        guard let metadata = await metadataProvider.getLocalStrigaMetadata()
        else {
            throw BankTransferError.missingMetadata
        }
        
        // get cached data from local provider
        if let cachedData = await localProvider.getCachedRegistrationData()
        {
            if let userId = await getUserId(),
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
            email: metadata.email,
            mobile: .init(
                countryCode: "",
                number: ""
            ),
            KYC: .init(
                status: .notStarted,
                mobileVerified: false
            )
        )
    }

    public func clearCache() async {
        await localProvider.clearRegistrationData()
    }

    public func simulateKYC(userId: String, status: String) async throws {
        try await remoteProvider.simulateStatus(userId: userId, status: status)
    }
}

// MARK: - Helpers

private extension String {
    static let expectedIncomingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let expectedOutgoingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let purposeOfAccount = "CRYPTO_PAYMENTS"
}
