//

import Foundation
import XCTest
import KeyAppNetworking
import SolanaSwift
import TweetNacl
@testable import BankTransfer

final class StrigaRemoteProviderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - GetKYCStatus

    func testGetKYCStatus_SuccessfulResponse_ReturnsStrigaKYC() async throws {
        // Arrange
        let mockData = #"{"userId":"9fd9f525-cb24-4682-8c5a-aa5c2b7e4dde","emailVerified":false,"mobileVerified":false,"status":"NOT_STARTED"}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let kycStatus = try await provider.getKYCStatus(userId: "123")
        
        // Assert
        XCTAssertEqual(kycStatus.mobileVerified, false)
        XCTAssertEqual(kycStatus.status, .notStarted)
    }

    // MARK: - GetUserDetails

    func testGetUserDetails_SuccessfulResponse_ReturnsStrigaUserDetailsResponse() async throws {
        // Arrange
        let mockData = #"{"firstName":"Claudia","lastName":"Tracy Lind","email":"test_1655832993@mailinator.com","documentIssuingCountry":"PS","nationality":"RS","mobile":{"countryCode":"+372","number":"56316716"},"dateOfBirth":{"month":"1","day":"15","year":"2000"},"address":{"addressLine1":"Sepapaja 12","addressLine2":"Hajumaa","city":"Tallinn","state":"Tallinn","country":"EE","postalCode":"11412"},"occupation":"PRECIOUS_GOODS_JEWELRY","sourceOfFunds":"CIVIL_CONTRACT","purposeOfAccount":"CRYPTO_PAYMENTS","selfPepDeclaration":true,"placeOfBirth":"Antoniettamouth","expectedIncomingTxVolumeYearly":"MORE_THAN_15000_EUR","expectedOutgoingTxVolumeYearly":"MORE_THAN_15000_EUR","KYC":{"emailVerified":true,"mobileVerified":true,"status":"REJECTED","details":["UNSATISFACTORY_PHOTOS","SCREENSHOTS","PROBLEMATIC_APPLICANT_DATA"],"rejectionComments":{"userComment":"The full name on the profile is either missing or incorrect.","autoComment":"Please enter your first and last name exactly as they are written in your identity document."}},"userId":"9fd9f525-cb24-4682-8c5a-aa5c2b7e4dde","createdAt":1655832993460}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let userDetails = try await provider.getUserDetails(userId: "123")
        
        // Assert
//        XCTAssertEqual(userDetails.userId, "9fd9f525-cb24-4682-8c5a-aa5c2b7e4dde")
        XCTAssertEqual(userDetails.firstName, "Claudia")
        XCTAssertEqual(userDetails.lastName, "Tracy Lind")
        XCTAssertEqual(userDetails.email, "test_1655832993@mailinator.com")
//        XCTAssertEqual(userDetails.documentIssuingCountry, "PS")
//        XCTAssertEqual(userDetails.nationality, "RS")
        XCTAssertEqual(userDetails.mobile.countryCode, "+372")
        XCTAssertEqual(userDetails.mobile.number, "56316716")
        XCTAssertEqual(userDetails.dateOfBirth?.month, "1")
        XCTAssertEqual(userDetails.dateOfBirth?.day, "15")
        XCTAssertEqual(userDetails.dateOfBirth?.year, "2000")
        XCTAssertEqual(userDetails.address?.addressLine1, "Sepapaja 12")
        XCTAssertEqual(userDetails.address?.addressLine2, "Hajumaa")
        XCTAssertEqual(userDetails.address?.city, "Tallinn")
        XCTAssertEqual(userDetails.address?.state, "Tallinn")
        XCTAssertEqual(userDetails.address?.country, "EE")
        XCTAssertEqual(userDetails.address?.postalCode, "11412")
        XCTAssertEqual(userDetails.occupation, .preciousGoodsJewelry)
        XCTAssertEqual(userDetails.sourceOfFunds, .civilContract)
//        XCTAssertEqual(userDetails.purposeOfAccount, "OTHER")
//        XCTAssertTrue(userDetails.selfPepDeclaration)
        XCTAssertEqual(userDetails.placeOfBirth, "Antoniettamouth")
//        XCTAssertEqual(userDetails.expectedIncomingTxVolumeYearly, "MORE_THAN_15000_EUR")
//        XCTAssertEqual(userDetails.expectedOutgoingTxVolumeYearly, "MORE_THAN_15000_EUR")
//        XCTAssertTrue(userDetails.KYC.emailVerified ?? false)
        XCTAssertTrue(userDetails.KYC.mobileVerified)
        XCTAssertEqual(userDetails.KYC.status, .rejected)
//        XCTAssertEqual(userDetails.KYC.details, ["UNSATISFACTORY_PHOTOS", "SCREENSHOTS", "PROBLEMATIC_APPLICANT_DATA"])
//        XCTAssertEqual(userDetails.KYC?.rejectionComments?.userComment, "The full name on the profile is either missing or incorrect.")
//        XCTAssertEqual(userDetails.KYC?.rejectionComments?.autoComment, "Please enter your first and last name exactly as they are written in your identity document.")
//        XCTAssertEqual(userDetails.createdAt, 1655832993460)
    }

    // MARK: - Create User

    func testCreateUser_SuccessfulResponse_ReturnsCreateUserResponse() async throws {
        // Arrange
        let mockData = #"{"userId":"de13f7b0-c159-4955-a226-42ca2e4f0b76","email":"test_1652858341@mailinator.com","KYC":{"status":"NOT_STARTED"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let response = try await provider.createUser(model: StrigaCreateUserRequest(
            firstName: "John",
            lastName: "Doe",
            email: "johndoe@example.com",
            mobile: StrigaCreateUserRequest.Mobile(countryCode: "+1", number: "1234567890"),
            dateOfBirth: StrigaCreateUserRequest.DateOfBirth(year: "1990", month: "01", day: "01"),
            address: StrigaCreateUserRequest.Address(
                addressLine1: "123 Main St",
                addressLine2: "Apt 4B",
                city: "New York",
                postalCode: "10001",
                state: "NY",
                country: "US"
            ),
            occupation: .artEntertainment,
            sourceOfFunds: .civilContract,
            ipAddress: "127.0.0.1",
            placeOfBirth: "New York",
            expectedIncomingTxVolumeYearly: "MORE_THAN_50000_USD",
            expectedOutgoingTxVolumeYearly: "MORE_THAN_50000_USD",
            selfPepDeclaration: true,
            purposeOfAccount: "Personal Savings"
        )
)
        
        // Assert
        XCTAssertEqual(response.userId, "de13f7b0-c159-4955-a226-42ca2e4f0b76")
        XCTAssertEqual(response.email, "test_1652858341@mailinator.com")
        XCTAssertEqual(response.KYC.status, .notStarted)
    }

    // MARK: - Verify phone number

    func testVerifyPhoneNumber_SuccessfulResponse_ReturnsAccepted() async throws {
        // Arrange
        let mockData = #"Accepted"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        try await provider.verifyMobileNumber(userId: "123", verificationCode: "123456")
        
        // Assert
        XCTAssertTrue(true)
    }
    
    func testVerifyPhoneNumber_EmptyResponse400_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 409)
        
        // Act
        do {
            try await provider.verifyMobileNumber(userId: "123", verificationCode: "123456")
            XCTFail()
        } catch HTTPClientError.invalidResponse(_, _) {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }
    
    func testVerifyPhoneNumber_ErrorDetail409_ReturnsOtpExceededVerification() async throws {
        // Arrange
        let mockData = #"{"status":409,"errorCode":"30003","errorDetails":{"message":"Exceeded verification attempts"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 409)
        
        // Act
        do {
            try await provider.verifyMobileNumber(userId: "123", verificationCode: "123456")
            XCTFail()
        } catch BankTransferError.otpExceededVerification {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }

    // MARK: - Resend SMS

    func testResendSMS_SuccessfulResponse_ReturnsAccepted() async throws {
        // Arrange
        let mockData = #"{"dateExpires":"2023-06-20T12:14:14.981Z"}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        try await provider.resendSMS(userId: "123")
        
        // Assert
        XCTAssertTrue(true)
    }
    
    func testResendSMS_ErrorDetail409_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{"message":"Mobile is already verified","errorCode":"00002","errorDetails":{"message":"Mobile is already verified","errorDetails":"885d9dd3-56d1-416b-a85b-873fcec69071"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 409)
        
        // Act
        do {
            try await provider.resendSMS(userId: "123")
            XCTFail()
        } catch BankTransferError.mobileAlreadyVerified {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }

    // MARK: - GetKYCToken

    func testGetKYCToken_SuccessfulResponse_ReturnsToken() async throws {
        // Arrange
        let mockData = #"{"provider":"SUMSUB","token":"_act-sbx-cc6a85f3-4315-4d26-b507-3e5ea31ff2f9","userId":"2f1853b2-927a-4aa9-8bb1-3e51fb119ace","verificationLink":"https://in.sumsub.com/idensic/l/#/sbx_Eke06K3fpzlbWuf3"}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let token = try await provider.getKYCToken(userId: "123")
        
        // Assert
        XCTAssertEqual(token, "_act-sbx-cc6a85f3-4315-4d26-b507-3e5ea31ff2f9")
    }
    
    func testGetKYCToken_InvalidFields400_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{"status":400,"errorCode":"00002","errorDetails":{"message":"Invalid fields","errorDetails":[{"msg":"Invalid value","param":"mobile.number","location":"body"}]}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 400)
        
        // Act
        do {
            let _ = try await provider.getKYCToken(userId: "123")
            XCTFail()
        } catch HTTPClientError.invalidResponse(_, _) {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }
    
    func testGetKYCToken_UserNotVerified409_ReturnsInvalidResponse() async throws {
        // Arrange
        let mockData = #"{"status":409,"errorCode":"30007","errorDetails":{"message":"User is not verified"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 409)
        
        // Act
        do {
            let _ = try await provider.getKYCToken(userId: "123")
            XCTFail()
        } catch HTTPClientError.invalidResponse(_, _) {
            XCTAssertTrue(true)
        } catch {
            XCTFail()
        }
    }

    // MARK: - GetAllUserWallets

    func testGetAllWalletsByUser_SuccessfulResponse_ReturnsStrigaGetAllWalletsResponse() async throws {
        // Arrange
        let mockData = #"{"wallets":[{"walletId":"3d57a943-8145-4183-8079-cd86b68d2993","accounts":{"EUR":{"accountId":"4dc6ecb29d74198e9e507f8025cad011","parentWalletId":"719c6236-0420-43c1-a7cb-1e20ce540a8d","currency":"EUR","ownerId":"80efa80b-2b53-4b80-be88-4fcaa7d3a540","ownerType":"CONSUMER","createdAt":"2023-06-26T14:06:00.673Z","availableBalance":{"amount":"0","currency":"cents"},"linkedCardId":"UNLINKED","linkedBankAccountId":"EUR13467658780233","status":"ACTIVE","permissions":["CUSTODY","TRADE","INTER","INTRA"],"enriched":true},"USDC":{"accountId":"140ecf6f979975c8e868d14038004b37","parentWalletId":"3d57a943-8145-4183-8079-cd86b68d2993","currency":"USDC","ownerId":"aa3534a1-d13d-4920-b023-97cb00d49bad","ownerType":"CONSUMER","createdAt":"2023-05-28T19:47:17.078Z","availableBalance":{"amount":"5889","currency":"cents"},"linkedCardId":"UNLINKED","blockchainDepositAddress":"0xF13607D9Ab2D98f6734Dc09e4CDE7dA515fe329c","blockchainNetwork":{"name":"USD Coin Test (Goerli)","type":"ERC20","contractAddress":"0x07865c6E87B9F70255377e024ace6630C1Eaa37F"},"status":"ACTIVE","permissions":["CUSTODY","TRADE","INTER","INTRA"],"enriched":true}},"syncedOwnerId":"80efa80b-2b53-4b80-be88-4fcaa7d3a540","ownerType":"CONSUMER","createdAt":"2023-06-26T14:06:00.693Z","comment":"DEFAULT"}],"count":1,"total":1}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let response = try await provider.getAllWalletsByUser(userId: "123", startDate: Date(), endDate: Date(), page: 1)
        
        // Assert the count and total values
        XCTAssertEqual(response.count, 1)
        XCTAssertEqual(response.total, 1)
        
        // Assert the wallets array
        XCTAssertEqual(response.wallets.count, 1)
        
        // Assert the first wallet
        let wallet = response.wallets[0]
        XCTAssertEqual(wallet.walletID, "3d57a943-8145-4183-8079-cd86b68d2993")
        
        // Assert the accounts within the wallet
        let accounts = wallet.accounts
        
        // Assert the EUR account
        let eurAccount = accounts.eur
        XCTAssertEqual(eurAccount?.accountID, "4dc6ecb29d74198e9e507f8025cad011")
        XCTAssertEqual(eurAccount?.currency, "EUR")
        // ... continue asserting other properties of the EUR account
        
        // Assert the USDC account
        let usdcAccount = accounts.usdc
        XCTAssertEqual(usdcAccount?.accountID, "140ecf6f979975c8e868d14038004b37")
        XCTAssertEqual(usdcAccount?.currency, "USDC")
        XCTAssertEqual(usdcAccount?.parentWalletID, "3d57a943-8145-4183-8079-cd86b68d2993")
        XCTAssertEqual(usdcAccount?.ownerID, "aa3534a1-d13d-4920-b023-97cb00d49bad")
        XCTAssertEqual(usdcAccount?.ownerType, "CONSUMER")
        XCTAssertEqual(usdcAccount?.createdAt, "2023-05-28T19:47:17.078Z")
        
        // Assert the available balance of USDC account
        let usdcAvailableBalance = usdcAccount?.availableBalance
        XCTAssertEqual(usdcAvailableBalance?.amount, "5889")
        XCTAssertEqual(usdcAvailableBalance?.currency, "cents")
        
        // Assert the linked card ID of USDC account
        XCTAssertEqual(usdcAccount?.linkedCardID, "UNLINKED")
        
        // Assert the blockchain deposit address of USDC account
        XCTAssertEqual(usdcAccount?.blockchainDepositAddress, "0xF13607D9Ab2D98f6734Dc09e4CDE7dA515fe329c")
        
        // Assert the blockchain network details of USDC account
        let usdcBlockchainNetwork = usdcAccount?.blockchainNetwork
        XCTAssertEqual(usdcBlockchainNetwork?.name, "USD Coin Test (Goerli)")
        XCTAssertEqual(usdcBlockchainNetwork?.type, "ERC20")
        XCTAssertEqual(usdcBlockchainNetwork?.contractAddress, "0x07865c6E87B9F70255377e024ace6630C1Eaa37F")
        
        // Assert the status of USDC account
        XCTAssertEqual(usdcAccount?.status, "ACTIVE")
        
        // Assert the permissions of USDC account
        let usdcPermissions = usdcAccount?.permissions
        XCTAssertEqual(usdcPermissions, ["CUSTODY", "TRADE", "INTER", "INTRA"])
        
        // Assert the enriched property of USDC account
        XCTAssertTrue(usdcAccount?.enriched ?? false)

    }

    // MARK: - Enrich account

    func testEnrichAccount_SuccessfulResponse_ReturnsEnrichedAccount() async throws {
        // Arrange
        let mockData = #"{"blockchainDepositAddress":"0x59d42C04022E926DAF16d139aFCBCa0da33E2323","blockchainNetwork":{"name":"Binance USD (BSC Test)","type":"BEP20","contractAddress":"0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee"}}"#
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)
        
        // Act
        let enrichedAccount: StrigaEnrichedUSDCAccountResponse = try await provider.enrichAccount(userId: "123", accountId: "456")
        
        // Assert
        XCTAssertEqual(enrichedAccount.blockchainDepositAddress, "0x59d42C04022E926DAF16d139aFCBCa0da33E2323")
        XCTAssertEqual(enrichedAccount.blockchainNetwork.name, "Binance USD (BSC Test)")
        XCTAssertEqual(enrichedAccount.blockchainNetwork.type, "BEP20")
        XCTAssertEqual(enrichedAccount.blockchainNetwork.contractAddress, "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee")
    }

    func testInitiateOnChainWalletSend_SuccessfulResponse() async throws {
        // Arrange
        let mockData = """
    {
        "challengeId": "eaec4a27-d78d-4f49-80bf-9c1ecba98853",
        "dateExpires": "2023-03-30T05:21:47.402Z",
        "transaction": {
            "syncedOwnerId": "51a2ed48-3b70-4775-b549-0d7e4850b64d",
            "sourceAccountId": "9c73b2f8a7c4e567c0460ef83c309ce1",
            "parentWalletId": "2c24c517-c682-4472-bbde-627e4a26fcf8",
            "currency": "ETH",
            "amount": "10000000000000000",
            "status": "PENDING_2FA_CONFIRMATION",
            "txType": "ON_CHAIN_WITHDRAWAL_INITIATED",
            "blockchainDestinationAddress": "0x6475C4E02248E463fDBbF2D3fB436aFCa9c56DbD",
            "blockchainNetwork": {
                "name": "Ethereum Test (Goerli)"
            },
            "transactionCurrency": "ETH"
        },
        "feeEstimate": {
            "totalFee": "948640405755000",
            "networkFee": "948640405755000",
            "ourFee": "948640405755000",
            "theirFee": "0",
            "feeCurrency": "ETH",
            "gasLimit": "21000",
            "gasPrice": "21.044"
        }
    }
"""
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)

        // Act
        let decodedData = try await provider.initiateOnChainWalletSend(
            userId: "123",
            sourceAccountId: "456",
            whitelistedAddressId: "789",
            amount: "100",
            accountCreation: true
        )

        // Assert
        XCTAssertEqual(decodedData.challengeId, "eaec4a27-d78d-4f49-80bf-9c1ecba98853")
        XCTAssertEqual(decodedData.dateExpires, "2023-03-30T05:21:47.402Z")

        XCTAssertEqual(decodedData.transaction.syncedOwnerId, "51a2ed48-3b70-4775-b549-0d7e4850b64d")
        XCTAssertEqual(decodedData.transaction.sourceAccountId, "9c73b2f8a7c4e567c0460ef83c309ce1")
        XCTAssertEqual(decodedData.transaction.parentWalletId, "2c24c517-c682-4472-bbde-627e4a26fcf8")
        XCTAssertEqual(decodedData.transaction.currency, "ETH")
        XCTAssertEqual(decodedData.transaction.amount, "10000000000000000")
        XCTAssertEqual(decodedData.transaction.status, "PENDING_2FA_CONFIRMATION")
        XCTAssertEqual(decodedData.transaction.txType, .initiated)
        XCTAssertEqual(decodedData.transaction.blockchainDestinationAddress, "0x6475C4E02248E463fDBbF2D3fB436aFCa9c56DbD")
        XCTAssertEqual(decodedData.transaction.blockchainNetwork.name, "Ethereum Test (Goerli)")
        XCTAssertEqual(decodedData.transaction.transactionCurrency, "ETH")

        XCTAssertEqual(decodedData.feeEstimate.totalFee, "948640405755000")
        XCTAssertEqual(decodedData.feeEstimate.networkFee, "948640405755000")
        XCTAssertEqual(decodedData.feeEstimate.ourFee, "948640405755000")
        XCTAssertEqual(decodedData.feeEstimate.theirFee, "0")
        XCTAssertEqual(decodedData.feeEstimate.feeCurrency, "ETH")
        XCTAssertEqual(decodedData.feeEstimate.gasLimit, "21000")
        XCTAssertEqual(decodedData.feeEstimate.gasPrice, "21.044")
    }

    func testTransactionResendOTP_SuccessfulResponse() async throws {
        // Arrange
        let mockData = """
            {
                "challengeId": "f56aaf67-acc1-4397-ae6b-57b553bdc5b0",
                "dateExpires": "2022-11-10T14:17:28.162Z",
                "attempts": 1
            }
        """
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)

        // Act
        let result = try await provider.transactionResendOTP(
            userId: "cecaea44-47f2-439b-99a1-a35fefaf1eb6",
            challengeId: "f56aaf67-acc1-4397-ae6b-57b553bdc5b0"
        )

        // Assert
        XCTAssertEqual(result.challengeId, "f56aaf67-acc1-4397-ae6b-57b553bdc5b0")
        XCTAssertEqual(result.dateExpires, "2022-11-10T14:17:28.162Z")
        XCTAssertEqual(result.attempts, 1)
    }

    func testProcessTransaction_SuccessfulResponse() async throws {
        // Arrange
        let mockData = """
        {
          "id": "e0a00ba5-6788-41c6-95f1-258b49b406a7",
          "amount": "50",
          "feeSats": "1",
          "invoice": "lntb500n1p3k6pj7pp5axdfq2mprvc9csgkgp0fhm3magqw8dp4f64gncwwpjlae2ke8zmqdqqcqzpgxqyz5vqsp5ey8e6twhw0rqnqer8ycsvx4mgy56nalxzqm08gwymj2sxa5s8qcq9qyyssqstksm7hq62vfkqrsv6vh283npc2c597l6mmvjplk84h3dmv5qzh4lusetk3v4pdfr4tcfj3ezf87sakhr9cc6eq8l238uev5mxdhv2gpds0fn3",
          "payeeNode": "020ec0c6a0c4fe5d8a79928ead294c36234a76f6e0dca896c35413612a3fd8dbf8",
          "network": {
            "bech32": "tb",
            "pubKeyHash": 111,
            "scriptHash": 196,
            "validWitnessVersions": [
              0,
              1
            ]
          }
        }
        """
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)

        // Act
        let result = try await provider.transactionConfirmOTP(
            userId: "cecaea44-47f2-439b-99a1-a35fefaf1eb6",
            challengeId: "123",
            code: "123456",
            ip: "ipString"
        )

        // Assert
        XCTAssertEqual(result.id, "e0a00ba5-6788-41c6-95f1-258b49b406a7")
        XCTAssertEqual(result.amount, "50")
        XCTAssertEqual(result.feeSats, "1")
        XCTAssertEqual(result.invoice, "lntb500n1p3k6pj7pp5axdfq2mprvc9csgkgp0fhm3magqw8dp4f64gncwwpjlae2ke8zmqdqqcqzpgxqyz5vqsp5ey8e6twhw0rqnqer8ycsvx4mgy56nalxzqm08gwymj2sxa5s8qcq9qyyssqstksm7hq62vfkqrsv6vh283npc2c597l6mmvjplk84h3dmv5qzh4lusetk3v4pdfr4tcfj3ezf87sakhr9cc6eq8l238uev5mxdhv2gpds0fn3")
        XCTAssertEqual(result.payeeNode, "020ec0c6a0c4fe5d8a79928ead294c36234a76f6e0dca896c35413612a3fd8dbf8")
        XCTAssertEqual(result.network.bech32, "tb")
        XCTAssertEqual(result.network.pubKeyHash, 111)
        XCTAssertEqual(result.network.scriptHash, 196)
        XCTAssertEqual(result.network.validWitnessVersions, [0, 1])
    }

    func testInitiateOnchainFeeEstimate_SuccessfulResponse() async throws {
        // Arrange
        let mockData = """
            {
                "totalFee": "909237719334000",
                "networkFee": "909237719334000",
                "ourFee": "909237719334000",
                "theirFee": "0",
                "feeCurrency": "ETH",
                "gasLimit": "21000",
                "gasPrice": "18.313"
            }
        """
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)

        let result = try await provider.initiateOnchainFeeEstimate(
            userId: "65367b0e-d569-44ad-bcb2-e004c9cd3646",
            sourceAccountId: "73e3aa3714c4488b6205b0f93fbbbd6f",
            whitelistedAddressId: "bed66a98-e36a-41e9-a478-3c6bf277d0d5",
            amount: "1210189000000000"
        )
    
        // Assert
        XCTAssertEqual(result.totalFee, "909237719334000")
        XCTAssertEqual(result.networkFee, "909237719334000")
        XCTAssertEqual(result.ourFee, "909237719334000")
        XCTAssertEqual(result.theirFee, "0")
        XCTAssertEqual(result.feeCurrency, "ETH")
        XCTAssertEqual(result.gasLimit, "21000")
        XCTAssertEqual(result.gasPrice, "18.313")
    }

    func testExchangeRates_SuccessfulResponse() async throws {
        // Arrange
        let mockData = """
            {"ETHEUR":{"price":"1693","buy":"1701.47","sell":"1684.53","timestamp":1689670715581,"currency":"Euros"},"USDCEUR":{"price":"0.9","buy":"0.9","sell":"0.88","timestamp":1689670714000,"currency":"Euros"},"USDCUSDT":{"price":"1","buy":"1.01","sell":"0.99","timestamp":1689670714000,"currency":"Tether"},"USDTEUR":{"price":"0.9","buy":"0.9","sell":"0.88","timestamp":1689670717071,"currency":"Euros"},"BTCEUR":{"price":"26729","buy":"26862.65","sell":"26595.35","timestamp":1689670717094,"currency":"Euros"},"BTCUSDC":{"price":"30026.55","buy":"30176.69","sell":"29876.41","timestamp":1689670714000,"currency":"USD Coin"},"BTCUSDT":{"price":"30017.27","buy":"30167.36","sell":"29867.18","timestamp":1689670717006,"currency":"Tether"},"BUSDEUR":{"price":"1.13","buy":"1.13","sell":"1.11","timestamp":1689670710865,"currency":"Binance USD"},"BNBEUR":{"price":"215.9","buy":"216.98","sell":"214.82","timestamp":1689670709965,"currency":"Euros"},"LINKBUSD":{"price":"7.06","buy":"7.1","sell":"7.02","timestamp":1689670716666,"currency":"Binance USD"},"MATICBUSD":{"price":"0.76","buy":"0.76","sell":"0.75","timestamp":1689670715736,"currency":"Binance USD"},"SUSHIBUSD":{"price":"0.74","buy":"0.75","sell":"0.73","timestamp":1689670715694,"currency":"Binance USD"},"UNIBUSD":{"price":"6.16","buy":"6.19","sell":"6.12","timestamp":1689670714011,"currency":"Binance USD"},"1INCHBUSD":{"price":"0.38","buy":"0.39","sell":"0.37","timestamp":1689670716518,"currency":"Binance USD"}}
        """
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)

        let result = try await provider.exchangeRates()

        // Assert
        XCTAssertNotNil(result["USDCEUR"])
        XCTAssertEqual(result["USDCEUR"]?.price, "0.9")
        XCTAssertEqual(result["USDCEUR"]?.buy, "0.9")
        XCTAssertEqual(result["USDCEUR"]?.sell, "0.88")
        XCTAssertEqual(result.isEmpty, false)
    }

    func testExchangeRates_FailedResponse() async throws {
        // Arrange
        var result: StrigaExchangeRatesResponse?
        let mockData = ""
        do {
            let provider = try getMockProvider(responseString: mockData, statusCode: 0, error: NSError(domain: "", code: NSURLErrorTimedOut))
            result = try await provider.exchangeRates()
        } catch let error {
            // Assert
            XCTAssertNil(result)
            XCTAssertEqual((error as NSError).code, NSURLErrorTimedOut)
        }
    }
    
    func testGetAccountStatement_SuccessfulEmptyResponse() async throws {
        // Arrange
        let mockData = """
            {"transactions":[],"count":0,"total":0}
        """
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)

        let result = try await provider.getAccountStatement(
            userId: "cecaea44-47f2-439b-99a1-a35fefaf1eb6",
            accountId: "4dc6ecb29d74198e9e507f8025cad011",
            startDate: Date(timeIntervalSince1970: 1687564800),
            endDate: Date(),
            page: 1
        )

        // Assert
        XCTAssertEqual(result.transactions.isEmpty, true)
    }
    
    func testGetAccountStatement_SuccessfulResponse() async throws {
        // Arrange
        let mockData = """
            {"transactions":[{"id":"af9d7fa5-4676-4190-ada1-06615c018f99","accountId":"d23cd18146112c1547be09a11ec2b7fb","syncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","sourceSyncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","destinationSyncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","debit":"5000","timestamp":"2023-07-20T13:54:36.826Z","txType":"EXCHANGE_DEBIT","txSubType":"CURRENCY_EXCHANGE_PENDING","memo":"Swap 5000 EUR to USDC","memoPayer":"Simulate Payin","exchangeRate":"1","balanceBefore":{"amount":"5000","currency":"cents"},"balanceAfter":{"amount":"0","currency":"cents"}},{"id":"a25e0dd1-8f4f-441d-a671-2f7d1e9738e6","accountId":"d23cd18146112c1547be09a11ec2b7fb","syncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","sourceSyncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","credit":"5000","timestamp":"2023-07-20T13:54:36.321Z","txType":"SEPA_PAYIN_COMPLETED","memo":"Simulate Payin","exchangeRate":"1","balanceBefore":{"amount":"0","currency":"cents"},"balanceAfter":{"amount":"5000","currency":"cents"},"bankingTransactionId":"a25e0dd1-8f4f-441d-a671-2f7d1e9738e6","bankingTransactionShortId":"20230720-MQ3R2H","bankingSenderBic":"BUKBGB22","bankingSenderIban":"GB29NWBK60161331926819","bankingSenderName":"Boris Johnson","bankingPaymentType":"SEPA","bankingSenderInformation":null,"bankingSenderRoutingCodes":[],"bankingSenderAccountNumber":null,"bankingTransactionDateTime":"2023-07-20T13:54:35.904836","bankingTransactionReference":"Simulate Payin"},{"id":"7c2075cb-7037-45f2-aeb6-dc1a61334f1a","accountId":"d23cd18146112c1547be09a11ec2b7fb","syncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","sourceSyncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","destinationSyncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","debit":"1000","timestamp":"2023-07-20T13:54:21.603Z","txType":"EXCHANGE_DEBIT","txSubType":"CURRENCY_EXCHANGE_PENDING","memo":"Swap 1000 EUR to USDC","memoPayer":"Simulate Payin","exchangeRate":"1","balanceBefore":{"amount":"1000","currency":"cents"},"balanceAfter":{"amount":"0","currency":"cents"}},{"id":"5c29131d-186e-47ad-a9c2-252368fc88ea","accountId":"d23cd18146112c1547be09a11ec2b7fb","syncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","sourceSyncedOwnerId":"54dd6616-f959-41b6-9d96-6d9fddaa3473","credit":"1000","timestamp":"2023-07-20T13:54:20.988Z","txType":"SEPA_PAYIN_COMPLETED","memo":"Simulate Payin","exchangeRate":"1","balanceBefore":{"amount":"0","currency":"cents"},"balanceAfter":{"amount":"1000","currency":"cents"},"bankingTransactionId":"5c29131d-186e-47ad-a9c2-252368fc88ea","bankingTransactionShortId":"20230720-RAF998","bankingSenderBic":"BUKBGB22","bankingSenderIban":"GB29NWBK60161331926819","bankingSenderName":"Boris Johnson","bankingPaymentType":"SEPA","bankingSenderInformation":null,"bankingSenderRoutingCodes":[],"bankingSenderAccountNumber":null,"bankingTransactionDateTime":"2023-07-20T13:54:19.754214","bankingTransactionReference":"Simulate Payin"}],"count":4,"total":4}
        """
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)

        let result = try await provider.getAccountStatement(
            userId: "cecaea44-47f2-439b-99a1-a35fefaf1eb6",
            accountId: "4dc6ecb29d74198e9e507f8025cad011",
            startDate: Date(timeIntervalSince1970: 1687564800),
            endDate: Date(),
            page: 1
        )

        // Assert
        XCTAssertEqual(result.transactions.isEmpty, false)
        XCTAssertEqual(result.transactions.contains(where: { $0.txType == "SEPA_PAYOUT_COMPLETED" }), false)
        XCTAssertEqual(result.transactions.contains(where: { $0.txType == "SEPA_PAYOUT_INITIATED" }), false)
        XCTAssertEqual(result.transactions.contains(where: { $0.txType == "SEPA_PAYIN_COMPLETED" }), true)
        XCTAssertNotNil(result.transactions.first(where: { $0.txType == "SEPA_PAYIN_COMPLETED" })?.bankingSenderIban)
        XCTAssertNotNil(result.transactions.first(where: { $0.txType == "SEPA_PAYIN_COMPLETED" })?.bankingSenderBic)
    }

    func testInitiateSEPAPayment_SuccessfulResponse() async throws {
        // Arrange
        let mockData = """
            {"challengeId":"924aa8d8-a377-4d61-8761-0b98a4f3f897","dateExpires":"2023-07-25T15:56:11.231Z","transaction":{"syncedOwnerId":"b861b16e-1070-4f54-b992-219549538526","sourceAccountId":"793815a2c66152e7de19318617860ba2","iban":"GB29NWBK60161331926819","bic":"BUKBGB22","amount":"574","status":"PENDING_2FA_CONFIRMATION","txType":"SEPA_PAYOUT_INITIATED","parentWalletId":"f4df3cc6-9c60-461a-8207-05cc8e6e7207","currency":"EUR","feeEstimate":{"totalFee":"0","networkFee":"0","ourFee":"0","theirFee":"0","feeCurrency":"EUR"}},"feeEstimate":{"totalFee":"0","networkFee":"0","ourFee":"0","theirFee":"0","feeCurrency":"EUR"}}
        """
        let provider = try getMockProvider(responseString: mockData, statusCode: 200)

        let result = try await provider.initiateSEPAPayment(
            userId: "cecaea44-47f2-439b-99a1-a35fefaf1eb6",
            accountId: "4dc6ecb29d74198e9e507f8025cad011",
            amount: "574",
            iban: "GB29NWBK60161331926819",
            bic: "BUKBGB22"
        )

        // Assert
        XCTAssertNotNil(result.challengeId)
        XCTAssertFalse(result.challengeId.isEmpty)
    }


    // MARK: - Helper Methods
    
    func getMockProvider(responseString: String, statusCode: Int, error: Error? = nil) throws -> StrigaRemoteProvider {
        let mockURLSession = MockURLSession(responseString: responseString, statusCode: statusCode, error: error)
        let httpClient = HTTPClient(urlSession: mockURLSession)
        return StrigaRemoteProviderImpl(baseURL: "https://example.com/api", solanaKeyPair: try KeyPair(), httpClient: httpClient)
    }
}
