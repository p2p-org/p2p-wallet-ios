import Foundation
import KeyAppNetworking
import Combine
import SolanaSwift
import TweetNacl
import KeyAppKitCore
import KeyAppKitLogger

public final class StrigaBankTransferUserDataRepository: BankTransferUserDataRepository {

    // MARK: - Properties

    private let localProvider: StrigaLocalProvider
    private let remoteProvider: StrigaRemoteProvider
    private let metadataProvider: StrigaMetadataProvider
    private let solanaKeyPair: KeyPair?

    // TODO: Consider removing commonInfoProvider from StrigaBankTransferUserDataRepository, because when more bank transfer providers will be added, we will need to have more general logic for this
    private let commonInfoProvider: CommonInfoLocalProvider

    // MARK: - Initializer

    public init(
        localProvider: StrigaLocalProvider,
        remoteProvider: StrigaRemoteProvider,
        metadataProvider: StrigaMetadataProvider,
        commonInfoProvider: CommonInfoLocalProvider,
        solanaKeyPair: KeyPair?
    ) {
        self.localProvider = localProvider
        self.remoteProvider = remoteProvider
        self.metadataProvider = metadataProvider
        self.commonInfoProvider = commonInfoProvider
        self.solanaKeyPair = solanaKeyPair
    }
    
    // MARK: - Methods

    public func getUserId() async -> String? {
        await metadataProvider.getStrigaMetadata()?.userId
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
        await metadataProvider.updateMetadata(withUserId: response.userId)
        
        // return
        return response
    }

    public func updateLocally(registrationData data: BankTransferRegistrationData) async throws {
        // assert response type
        guard let data = data as? StrigaUserDetailsResponse else {
            throw StrigaProviderError.invalidRequest("Data mismatch")
        }

        try? await localProvider.save(registrationData: data)

        // Update common info with latest striga information
        let commonInfo = UserCommonInfo(
            firstName: data.firstName,
            lastName: data.lastName,
            placeOfBirth: data.placeOfBirth,
            dateOfBirth: DateOfBirth(year: data.dateOfBirth?.year, month: data.dateOfBirth?.month, day: data.dateOfBirth?.day)
        )
        try? await commonInfoProvider.save(commonInfo: commonInfo)
    }

    public func updateLocally(userData data: UserData) async throws {
        try? await localProvider.save(userData: data)
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
        } else if let userId = await getUserId(), let response = try? await remoteProvider.getUserDetails(userId: userId) {
            // Make request for userDetails if there is a userId and no cached data
            try await localProvider.save(registrationData: response)
            return response
        }

        // get metadata
        guard let metadata = await metadataProvider.getStrigaMetadata()
        else {
            throw BankTransferError.missingMetadata
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
        await localProvider.clear()
        await commonInfoProvider.clear()
    }

    public func getWallet(userId: String) async throws -> UserWallet? {
        var wallet: UserWallet? = await localProvider.getCachedUserData()?.wallet
        do {
             var userWallet = try await remoteProvider.getAllWalletsByUser(
                userId: userId,
                startDate: Date(timeIntervalSince1970: 1687564800),
                endDate: Date(),
                page: 1
            ).wallets.map {
                UserWallet($0, cached: wallet)
            }.first

            if let account = userWallet?.accounts.usdc {
                do {
                    let fee = try await getFeeFor(userId: userId, account: account)
                    let avBalance = account.availableBalance - fee
                    userWallet?.accounts.usdc?.setAvailableBalance(max(0, avBalance))
                } catch {
                    Logger.log(
                        event: "Striga get estimated fee",
                        message: error.localizedDescription,
                        logLevel: KeyAppKitLoggerLogLevel.warning
                    )
                }
                wallet = userWallet
            }
        } catch {
            Logger.log(
                event: "Striga get all wallets",
                message: error.localizedDescription,
                logLevel: KeyAppKitLoggerLogLevel.warning
            )
        }

        if let eur = wallet?.accounts.eur, !eur.enriched {
            do {
                let response: StrigaEnrichedEURAccountResponse = try await enrichAccount(
                    userId: userId,
                    accountId: eur.accountID
                )
                wallet?.accounts.eur = EURUserAccount(
                    accountID: eur.accountID,
                    currency: eur.currency,
                    createdAt: eur.createdAt,
                    enriched: true,
                    iban: response.iban,
                    bic: response.bic,
                    bankAccountHolderName: response.bankAccountHolderName
                )
            } catch {
                // Skip error, do not block the flow
                Logger.log(
                    event: "Striga EUR Enrichment",
                    message: error.localizedDescription,
                    logLevel: KeyAppKitLoggerLogLevel.warning
                )
            }
        }

        do {
            // Whitelist address
            try await addWhitelistIfNeeded(
                for: userId,
                account: wallet?.accounts.usdc
            )
        } catch {
            Logger.log(
                event: "Striga add to Whitelist",
                message: error.localizedDescription,
                logLevel: KeyAppKitLoggerLogLevel.warning
            )
        }

        if let usdc = wallet?.accounts.usdc, !usdc.enriched {
            do {
                let response: StrigaEnrichedUSDCAccountResponse = try await enrichAccount(
                    userId: userId,
                    accountId: usdc.accountID
                )
                var fee = 0
                do {
                    fee = try await getFeeFor(userId: userId, account: usdc)
                } catch {
                    Logger.log(
                        event: "Striga get estimated fee",
                        message: error.localizedDescription,
                        logLevel: KeyAppKitLoggerLogLevel.warning
                    )
                }
                wallet?.accounts.usdc = USDCUserAccount(
                    accountID: usdc.accountID,
                    currency: usdc.currency,
                    createdAt: usdc.createdAt,
                    enriched: true,
                    blockchainDepositAddress: response.blockchainDepositAddress,
                    availableBalance: max(0, usdc.availableBalance - fee),
                    totalBalance: usdc.availableBalance
                )
            } catch {
                // Skip error, do not block the flow
                Logger.log(
                    event: "Striga USDC Enrichment",
                    message: error.localizedDescription,
                    logLevel: KeyAppKitLoggerLogLevel.warning
                )
            }
        }
        return wallet
    }

    public func claimVerify(userId: String, challengeId: String, ip: String, verificationCode code: String) async throws {
        _ = try await remoteProvider.transactionConfirmOTP(userId: userId, challengeId: challengeId, code: code, ip: ip)
    }
    
    public func claimResendSMS(userId: String, challengeId: String) async throws {
        _ = try await remoteProvider.transactionResendOTP(userId: userId, challengeId: challengeId)
    }

    public func whitelistIdFor(account: USDCUserAccount) async throws -> String? {
        return try await localProvider.getWhitelistedUserDestinations()
            .filter({ response in
                response.address == solanaKeyPair?.publicKey.base58EncodedString
                && response.currency == account.currency
            })
            .first?.id
    }

    public func addWhitelistIfNeeded(for userId: String, account: USDCUserAccount?) async throws {
        guard
            let address = solanaKeyPair?.publicKey.base58EncodedString,
            let currency = account?.currency,
            let account,
            try await whitelistIdFor(account: account) == nil
        else { return }
        do {
            _ = try await remoteProvider.whitelistDestinationAddress(
                userId: userId,
                address: address,
                currency: currency,
                network: "SOL",
                label: "SOL"
            )
        } catch HTTPClientError.invalidResponse(_, let data) {
            let res = try? JSONDecoder().decode(StrigaRemoteProviderError.self, from: data)
            if StrigaWhitelistAddressError(rawValue: res?.errorCode ?? "") != .alreadyWhitelisted {
                throw BankTransferError.missingMetadata
            }
        }

        let whitelisted = try await remoteProvider.getWhitelistedUserDestinations(
            userId: userId,
            currency: account.currency,
            label: "SOL",
            page: "0"
        ).addresses
        try? await localProvider.save(whitelisted: whitelisted)
    }

    public func initiateOnchainWithdrawal(
        userId: String,
        sourceAccountId: String,
        whitelistedAddressId: String,
        amount: String,
        accountCreation: Bool
    ) async throws -> StrigaWalletSendResponse {
        try await remoteProvider.initiateOnChainWalletSend(
            userId: userId,
            sourceAccountId: sourceAccountId,
            whitelistedAddressId: whitelistedAddressId,
            amount: amount,
            accountCreation: accountCreation
        )
    }

    // MARK: - Private
    private func enrichAccount<T: Decodable>(userId: String, accountId: String) async throws -> T {
        try await remoteProvider.enrichAccount(userId: userId, accountId: accountId)
    }

    private func getFeeFor(userId: String, account: USDCUserAccount) async throws -> Int {
        guard let whitelistId = try await whitelistIdFor(account: account) else {
            throw BankTransferError.missingUserId
        }
        let fees = try await remoteProvider.initiateOnchainFeeEstimate(
            userId: userId,
            sourceAccountId: account.accountID,
            whitelistedAddressId: whitelistId,
            amount: "\(account.totalBalance)"
        )
        return Int(fees.totalFee) ?? 0
    }
}

// MARK: - Helpers

private extension String {
    static let expectedIncomingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let expectedOutgoingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let purposeOfAccount = "CRYPTO_PAYMENTS"
}

private extension UserWallet {
    init(_ wallet: StrigaWallet, cached: UserWallet?) {
        var eur: EURUserAccount?
        if let eurAccount = wallet.accounts.eur {
            eur = EURUserAccount(
                accountID: eurAccount.accountID,
                currency: eurAccount.currency,
                createdAt: eurAccount.createdAt,
                enriched: cached?.accounts.eur?.enriched ?? false,
                iban: cached?.accounts.eur?.iban,
                bic: cached?.accounts.eur?.bic,
                bankAccountHolderName: cached?.accounts.eur?.bankAccountHolderName
            )
        }
        var usdc: USDCUserAccount?
        if let usdcAccount = wallet.accounts.usdc {
            usdc = USDCUserAccount(
                accountID: usdcAccount.accountID,
                currency: usdcAccount.currency,
                createdAt: usdcAccount.createdAt,
                enriched: cached?.accounts.usdc?.enriched ?? false,
                blockchainDepositAddress: cached?.accounts.usdc?.blockchainDepositAddress,
                availableBalance: Int(usdcAccount.availableBalance.amount) ?? 0,
                totalBalance: Int(usdcAccount.availableBalance.amount) ?? 0
            )
        }
        self.walletId = wallet.walletID
        self.accounts = UserAccounts(eur: eur, usdc: usdc)
    }
}
