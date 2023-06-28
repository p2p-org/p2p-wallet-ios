import Combine
import Foundation
import KeyAppKitCore

/// Default implementation of `BankTransferService`
public final class BankTransferServiceImpl {
    
    /// Repository that handle CRUD action for UserData
    public let repository: BankTransferUserDataRepository
    
    /// Subject that holds State with UserData stream
    public let subject = CurrentValueSubject<AsyncValueState<UserData>, Never>(
        AsyncValueState<UserData>(status: .initializing, value: .empty)
    )
    
    // MARK: - Initializers
    
    public init(repository: BankTransferUserDataRepository) {
        self.repository = repository
    }
}

extension BankTransferServiceImpl: BankTransferService {
    
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
            if let metadata = await repository.getMetadata(), let userId = metadata.userId {
                return try await handleRegisteredUser(userId: userId, mobileNumber: metadata.phoneNumber)
            }
            
            // unregistered user
            else {
                return try await handleUnregisteredUser()
            }
        } catch {
            return handleError(error: error)
        }
    }

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

    // MARK: - Helpers

    private func handleRegisteredUser(userId: String, mobileNumber: String) async throws {
        // get user details, check kyc status
        let kycStatus = try await repository.getKYCStatus()

        var wallets: [UserWallet]?
        if kycStatus.status == .approved {
            wallets = await handleUserWallets(userId: userId)
        }

        // update
        subject.send(
            .init(
                status: .ready,
                value: subject.value.value.updated(
                    userId: userId,
                    mobileVerified: kycStatus.mobileVerified,
                    kycStatus: kycStatus.status,
                    mobileNumber: mobileNumber,
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

    private func handleUserWallets(userId: String) async -> [UserWallet] {
        var wallets = try? await repository.getAllWalletsByUser(userId: userId)

        if let eur = wallets?.first?.accounts.eur, !eur.enriched {
            let response: StrigaEnrichedEURAccountResponse? = try? await repository.enrichAccount(userId: userId, accountId: eur.accountID)
            wallets?[0].accounts.eur = UserEURAccount(accountID: eur.accountID, currency: eur.currency, createdAt: eur.createdAt, enriched: true, iban: response?.iban, bic: response?.bic, bankAccountHolderName: response?.bankAccountHolderName)
        }

        if let usdc = wallets?.first?.accounts.usdc, !usdc.enriched {
            let response: StrigaEnrichedUSDCAccountResponse? = try? await repository.enrichAccount(userId: userId, accountId: usdc.accountID)
            wallets?[0].accounts.usdc = UserUSDCAccount(accountID: usdc.accountID, currency: usdc.currency, createdAt: usdc.createdAt, enriched: true, blockchainDepositAddress: response?.blockchainDepositAddress)
        }

        return wallets ?? []
    }
}
