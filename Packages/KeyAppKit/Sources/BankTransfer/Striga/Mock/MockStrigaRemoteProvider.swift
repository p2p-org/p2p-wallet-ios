import Foundation

public final class MockStrigaRemoteProvider: StrigaRemoteProvider {
    // MARK: - Properties

    private var useCase: MockStrigaUseCase
    private let mockUserId: String
    private let mockKYCToken: String

    // MARK: - Initializer

    public init(
        useCase: MockStrigaUseCase,
        mockUserId: String,
        mockKYCToken: String
    ) {
        self.useCase = useCase
        self.mockUserId = mockUserId
        self.mockKYCToken = mockKYCToken
    }

    // MARK: - Methods

    public func getKYCStatus(userId _: String) async throws -> StrigaKYC {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let mobileVerified: Bool

        switch useCase {
        case .unregisteredUser, .registeredUserWithUnverifiedOTP:
            mobileVerified = false
        case .registeredUserWithoutKYC, .registeredAndVerifiedUser:
            mobileVerified = true
        }

        // return value
        switch useCase {
        case .unregisteredUser, .registeredUserWithUnverifiedOTP, .registeredUserWithoutKYC:
            return .init(status: .notStarted, mobileVerified: mobileVerified)
        case .registeredAndVerifiedUser:
            return .init(status: .approved, mobileVerified: mobileVerified)
        }
    }

    public func getUserDetails(userId _: String) async throws -> StrigaUserDetailsResponse {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // return value
        return try .init(
            firstName: "Remote",
            lastName: "Provider",
            email: "remote.provider@mocking.com",
            mobile: .init(countryCode: "1", number: "5853042520"),
            dateOfBirth: .init(year: "1986", month: "12", day: "1"),
            address: .init(
                addressLine1: "Remote street 12",
                addressLine2: nil,
                city: "Remote Provider",
                postalCode: "12345",
                state: "Remote Provider",
                country: "USA"
            ),
            occupation: nil,
            sourceOfFunds: nil,
            placeOfBirth: nil,
            KYC: await getKYCStatus(userId: mockUserId)
        )
    }

    public func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse {
        // Fake network request
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // return value
        useCase = .registeredUserWithUnverifiedOTP

        // return value
        return .init(
            userId: mockUserId,
            email: model.email,
            KYC: .init(
                status: .notStarted
            )
        )
    }

    public func verifyMobileNumber(userId _: String, verificationCode _: String) async throws {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // all goods
        // return value
        useCase = .registeredUserWithoutKYC
    }

    var invokedResendSMS = false
    var invokedResendSMSCount = 0
    var invokedResendSMSParameters: (userId: String, Void)?
    var invokedResendSMSParametersList = [(userId: String, Void)]()

    public func resendSMS(userId _: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        // all goods
    }

    public func getKYCToken(userId _: String) async throws -> String {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // return value
        switch useCase {
        case .unregisteredUser, .registeredUserWithUnverifiedOTP, .registeredAndVerifiedUser:
            return ""
        case .registeredUserWithoutKYC:
            return mockKYCToken
        }
    }

    public func getAllWalletsByUser(userId _: String, startDate _: Date, endDate _: Date,
                                    page _: Int) async throws -> StrigaGetAllWalletsResponse
    {
        fatalError("Implementing")
    }

    public func enrichAccount<T>(userId _: String, accountId _: String) async throws -> T where T: Decodable {
        fatalError("Implementing")
    }

    public func initiateOnChainWalletSend(
        userId _: String,
        sourceAccountId _: String,
        whitelistedAddressId _: String,
        amount _: String,
        accountCreation _: Bool
    ) async throws -> StrigaWalletSendResponse {
        fatalError("Implementing")
    }

    public func transactionResendOTP(userId _: String,
                                     challengeId _: String) async throws -> StrigaTransactionResendOTPResponse
    {
        fatalError("Implementing")
    }

    public func transactionConfirmOTP(userId _: String, challengeId _: String, code _: String,
                                      ip _: String) async throws -> StrigaTransactionConfirmOTPResponse
    {
        fatalError("Implementing")
    }

    public func getWhitelistedUserDestinations() async throws -> [StrigaWhitelistAddressResponse] {
        fatalError("Implementing")
    }

    public func initiateOnchainFeeEstimate(
        userId _: String,
        sourceAccountId _: String,
        whitelistedAddressId _: String,
        amount _: String
    ) async throws -> FeeEstimateResponse {
        FeeEstimateResponse(
            totalFee: "909237719334000",
            networkFee: "909237719334000",
            ourFee: "909237719334000",
            theirFee: "0",
            feeCurrency: "USDC",
            gasLimit: "21000",
            gasPrice: "18.313"
        )
    }

    public func getWhitelistedUserDestinations(
        userId _: String,
        currency _: String?,
        label _: String?,
        page _: String?
    ) async throws -> StrigaWhitelistAddressesResponse {
        fatalError()
    }

    public func whitelistDestinationAddress(
        userId _: String,
        address _: String,
        currency _: String,
        network _: String,
        label _: String?
    ) async throws -> StrigaWhitelistAddressResponse {
        fatalError()
    }

    public func exchangeRates() async throws -> StrigaExchangeRatesResponse {
        ["USDCEUR": StrigaExchangeRates(price: "0.9", buy: "0.9", sell: "0.88",
                                        timestamp: Int(Date().timeIntervalSince1970), currency: "Euros")]
    }

    public func getAccountStatement(
        userId _: String,
        accountId _: String,
        startDate _: Date,
        endDate _: Date,
        page _: Int
    ) async throws -> StrigaGetAccountStatementResponse {
        StrigaGetAccountStatementResponse(transactions: [
            StrigaGetAccountStatementResponse.Transaction(
                id: "a25e0dd1-8f4f-441d-a671-2f7d1e9738e6",
                txType: "SEPA_PAYIN_COMPLETED",
                bankingSenderBic: "BUKBGB22",
                bankingSenderIban: "GB29NWBK60161331926819"
            ),
        ])
    }

    public func initiateSEPAPayment(
        userId _: String,
        accountId _: String,
        amount _: String,
        iban _: String,
        bic _: String
    ) async throws -> StrigaInitiateSEPAPaymentResponse {
        fatalError()
    }
}
