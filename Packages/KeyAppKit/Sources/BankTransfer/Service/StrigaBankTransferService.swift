import Combine
import Foundation
import SolanaSwift
import TweetNacl

private extension String {
    static let expectedIncomingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let expectedOutgoingTxVolumeYearly = "MORE_THAN_15000_EUR"
    static let purposeOfAccount = "CRYPTO_PAYMENTS"
}

typealias AuthHeader = StrigaEndpoint.AuthHeader

public final class StrigaBankTransferService {
    
    // Dependencies
    private let strigaProvider: IStrigaProvider
    
    // Properties
    private let keyPair: KeyPair
    
    // Subjects
    let subject = CurrentValueSubject<UserData, Never>(
        UserData(countryCode: nil, userId: nil, mobileVerified: false)
    )
    
    // MARK: - Init
    
    public init(
        strigaProvider: IStrigaProvider,
        keyPair: KeyPair
    ) {
        self.strigaProvider = strigaProvider
        self.keyPair = keyPair
    }
}

// MARK: - BankTransferService

extension StrigaBankTransferService: BankTransferService {

    public func save(userData: UserData) throws {
        fatalError("Not implemented")
    }
    
    public var userData: AnyPublisher<UserData, Never> { subject.eraseToAnyPublisher() }
    
    public func reload() async {
        fatalError("Not implemented")
    }

    public func isBankTransferAvailable() -> Bool {
        fatalError("Not implemented")
    }

    public func getRegistrationData() async throws -> RegistrationData {
//        if let cachedData {
//            return cachedData
//        } else {
        guard
            let authHeader = authHeader(keyPair: keyPair),
            let userId = subject.value.userId
        else { throw NSError(domain: "", code: 0) }
        return try await strigaProvider.getUserDetails(authHeader: authHeader, userId: userId).asDomain()
//        }
    }

    public func createUser(data: RegistrationData) async throws {
        let model = CreateUserRequest(
            firstName: data.firstName,
            lastName: data.lastName,
            email: data.email,
            mobile: CreateUserRequest.Mobile(countryCode: data.phoneCountryCode, number: data.phoneNumber),
            dateOfBirth: nil,
            address: nil,
            occupation: data.occupation,
            sourceOfFunds: nil,
            ipAddress: nil,
            placeOfBirth: data.placeOfBirth,
            expectedIncomingTxVolumeYearly: .expectedIncomingTxVolumeYearly,
            expectedOutgoingTxVolumeYearly: .expectedOutgoingTxVolumeYearly,
            selfPepDeclaration: false,
            purposeOfAccount: .purposeOfAccount
        )
        guard let authHeader = authHeader(keyPair: keyPair) else { throw NSError(domain: "", code: 0) }
        Task {
            do {
                let response = try await strigaProvider.createUser(authHeader: authHeader, model: model)
                debugPrint("---response: ", response)
            } catch {
                debugPrint("---error: ", error)
            }
        }
    }

    public func getOTP() async throws {
        fatalError("Not implemented")
    }

    public func verify(OTP: String) async throws -> Bool {
        fatalError("Not implemented")
    }
}

// MARK: - Auth Headers

private extension StrigaBankTransferService {
    func authHeader(keyPair: KeyPair) -> AuthHeader? {
        guard let signedMessage = getSignedTimestampMessage(keyPair: keyPair) else { return nil }
        return AuthHeader(pubKey: keyPair.publicKey.base58EncodedString, signedMessage: signedMessage)
    }
    
    func getSignedTimestampMessage(keyPair: KeyPair) -> String? {
        // get timestamp
        let timestamp = "\(Int(NSDate().timeIntervalSince1970) * 1_000)"
        
        // form message
        guard
            let data = timestamp.data(using: .utf8),
            let signedTimestampMessage = try? NaclSign.signDetached(
                message: data,
                secretKey: keyPair.secretKey
            ).base64EncodedString()
        else { return nil }
        // return unixtime:signature_of_unixtime_by_user_privatekey_in_base64_format
        return [timestamp, signedTimestampMessage].joined(separator: ":")
    }
}
