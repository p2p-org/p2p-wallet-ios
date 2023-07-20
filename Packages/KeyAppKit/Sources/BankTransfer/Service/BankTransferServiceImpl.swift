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

    // MARK: - Private

    /// Used to cache last KYC status
    private var cachedKYC: StrigaKYC? // It has StrigaKYCStatus type because it's used in BankTransferService protocol
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
                value: subject.value.value,
                error: subject.value.error
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

    // MARK: - Helpers

    private func handleRegisteredUser(userId: String) async throws {
        // check kyc status
        var kycStatus: StrigaKYC
        if let cachedKYC {
            kycStatus = cachedKYC
        } else {
            kycStatus = try await repository.getKYCStatus()
            // If status is approved -- cache response, ignore other fields
            cachedKYC = kycStatus.status == .approved ? kycStatus : nil
        }
        // get user details
        let registrationData = try await repository.getRegistrationData()

        var wallet: UserWallet?
        if kycStatus.status == .approved {
            wallet = try? await repository.getWallet(userId: userId)
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
                    wallet: wallet
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
    
    public func withdrawalInfo() async throws -> Provider.WithdrawalInfo? {
        try await repository.withdrawalInfo()
    
    }

    public func saveWithdrawalInfo(info: Provider.WithdrawalInfo) async throws {
        try await repository.save(info)
    }
}
