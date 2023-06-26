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

    public func getMetadata() async -> StrigaMetadata? {
        await metadataProvider.getStrigaMetadata()
    }
    
    public func getKYCStatus() async throws -> StrigaKYC {
        guard let userId = await getMetadata()?.userId else {
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
        guard let metadata = await metadataProvider.getStrigaMetadata()
        else {
            throw BankTransferError.missingMetadata
        }
        
        // get cached data from local provider
        if let cachedData = await localProvider.getCachedRegistrationData()
        {
            if let userId = await getMetadata()?.userId,
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

    public func getAllWalletsByUser(userId: String) async throws -> UserAccounts {
        let fixedStartDate = Date(timeIntervalSince1970: 1687564800)
        let fixedEndDate = Date()
        let allWallets = try await remoteProvider.getAllWalletsByUser(
            userId: userId,
            startDate: fixedStartDate,
            endDate: fixedEndDate,
            page: 1
        ).wallets.first
        var eur: WalletAccount?
        if let eurAccount = allWallets?.accounts.eur {
            eur = WalletAccount(accountID: eurAccount.accountID)
        }
        var usdc: WalletAccount?
        if let usdcAccount = allWallets?.accounts.usdc {
            usdc = WalletAccount(accountID: usdcAccount.accountID)
        }
        return UserAccounts(eur: eur, usdc: usdc)
    }

    public func enrichAccount<T: Decodable>(userId: String, accountId: String) async throws -> T {
        try await remoteProvider.enrichAccount(userId: userId, accountId: accountId)
    }
}

// MARK: - Helpers

private extension String {
    static let expectedIncomingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let expectedOutgoingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let purposeOfAccount = "CRYPTO_PAYMENTS"
}
