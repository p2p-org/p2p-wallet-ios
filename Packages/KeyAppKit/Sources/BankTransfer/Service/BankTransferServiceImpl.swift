import Combine
import Foundation
import KeyAppKitCore

/// Default implementation of `BankTransferService`
public final class BankTransferServiceImpl<T: BankTransferUserDataRepository>: BankTransferService {
    public typealias Provider = T
    
    /// Repository that handle CRUD action for UserData
    public let repository: Provider
    
    /// Subject that holds State with UserData stream
    public let subject = CurrentValueSubject<AsyncValueState<UserData>, Never>(
        AsyncValueState<UserData>(status: .initializing, value: .empty)
    )
    
    // MARK: - Initializers
    
    public init(repository: Provider) {
        self.repository = repository
    }
}

extension BankTransferServiceImpl {

    public var state: AnyPublisher<AsyncValueState<UserData>, Never> {
        subject.eraseToAnyPublisher()
    }
        
    public func reload() async {
        // mark as loading
        subject.send(
            .init(
                status: .fetching,
                value: .empty,
                error: nil
            )
        )
        
        do {
            // registered user
            if let userId = await repository.getUserId() {
                return try await handleRegisteredUser(userId: userId)
            }
            
            // unregistered user
            else {
                return try await handleUnregisteredUser()
            }
        } catch {
            return handleError(error: error)
        }
    }

    // MARK: - Registration

    public func getRegistrationData() async throws -> BankTransferRegistrationData {
        try await repository.getRegistrationData()
    }
    
    public func updateLocally(data: BankTransferRegistrationData) async throws {
        try await repository.updateLocally(registrationData: data)
    }
    
    public func createUser(data: BankTransferRegistrationData) async throws {
        let response = try await repository.createUser(registrationData: data)
        subject.send(
            .init(
                status: subject.value.status,
                value: subject.value.value.updated(
                    userId: response.userId,
                    kycStatus: response.KYC.status,
                    mobileNumber: data.mobileNumber
                ),
                error: subject.value.error
            )
        )
    }
    
    public func verify(OTP: String) async throws {
        guard let userId = subject.value.value.userId else { throw BankTransferError.missingUserId }
        try await repository.verifyMobileNumber(userId: userId, verificationCode: OTP)
        
        subject.send(
            .init(
                status: .ready,
                value: subject.value.value.updated(
                    mobileVerified: true
                ),
                error: nil
            )
        )
    }
    
    public func resendSMS() async throws {
        guard let userId = subject.value.value.userId else { throw BankTransferError.missingUserId }
        try await repository.resendSMS(userId: userId)
    }
    
    public func getKYCToken() async throws -> String {
        guard let userId = subject.value.value.userId else { throw BankTransferError.missingUserId }
        return try await repository.getKYCToken(userId: userId)
    }
    
    public func clearCache() async {
        await repository.clearCache()
    }

    // MARK: - Claim

//    public func claimVerify(OTP: String, challengeId: String, ip: String) async throws {
//        guard let userId = subject.value.value.userId else { throw BankTransferError.missingUserId }
//        try await repository.claimVerify(userId: userId, challengeId: challengeId, ip: ip, verificationCode: OTP)
//    }
    
    public func claimResendSMS(challengeId: String) async throws {
        guard let userId = subject.value.value.userId else { throw BankTransferError.missingUserId }
        try await repository.claimResendSMS(userId: userId, challengeId: challengeId)
    }

    // MARK: - Helpers

    private func handleRegisteredUser(userId: String) async throws {
        // check kyc status
        let kycStatus = try await repository.getKYCStatus()
        // get user details
        let registrationData = try await repository.getRegistrationData()

        var wallets: [UserWallet]?
        if kycStatus.status == .approved {
            do {
                wallets = try await handleUserWallets(userId: userId)
            } catch {
                handleError(error: error)
            }
        }

        // update
        subject.send(
            .init(
                status: .ready,
                value: subject.value.value.updated(
                    userId: userId,
                    mobileVerified: kycStatus.mobileVerified,
                    kycStatus: kycStatus.status,
                    mobileNumber: registrationData.mobileNumber,
                    wallets: wallets
                ),
                error: nil
            )
        )

        try? await repository.updateLocally(userData: subject.value.value)
    }
    
    private func handleUnregisteredUser() async throws {
        subject.send(
            .init(
                status: .ready,
                value: .empty,
                error: nil
            )
        )
    }
    
    private func handleError(error: Error) {
        subject.send(
            .init(
                status: .ready,
                value: .empty,
                error: error
            )
        )
    }

    private func handleUserWallets(userId: String) async throws -> [UserWallet] {
        var wallets = try await repository.getAllWalletsByUser(userId: userId)

        if let eur = wallets.first?.accounts.eur, !eur.enriched {
            let response: StrigaEnrichedEURAccountResponse = try await repository.enrichAccount(userId: userId, accountId: eur.accountID)
            wallets[0].accounts.eur = EURUserAccount(accountID: eur.accountID, currency: eur.currency, createdAt: eur.createdAt, enriched: true, iban: response.iban, bic: response.bic, bankAccountHolderName: response.bankAccountHolderName)
        }

        if let usdc = wallets.first?.accounts.usdc, !usdc.enriched {
            let response: StrigaEnrichedUSDCAccountResponse = try await repository.enrichAccount(userId: userId, accountId: usdc.accountID)
            wallets[0].accounts.usdc = USDCUserAccount(accountID: usdc.accountID, currency: usdc.currency, createdAt: usdc.createdAt, enriched: true, blockchainDepositAddress: response.blockchainDepositAddress)
        }

        return wallets
    }
}
