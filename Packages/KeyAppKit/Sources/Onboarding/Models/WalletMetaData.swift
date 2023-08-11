import Foundation
import KeyAppKitCore

public struct WalletMetaData: Codable, Equatable {
    public static let ethPublicInfoKey = CodingUserInfoKey(rawValue: "ethPublic")!

    public let ethPublic: String

    public var deviceName: String { didSet { deviceNameTimestamp = Date.currentTimestamp() } }

    public internal(set) var deviceNameTimestamp: UInt64

    public var email: String { didSet { emailTimestamp = Date.currentTimestamp() } }

    public internal(set) var emailTimestamp: UInt64

    public var authProvider: String { didSet { authProviderTimestamp = Date.currentTimestamp() } }

    public internal(set) var authProviderTimestamp: UInt64

    public var phoneNumber: String { didSet { phoneNumberTimestamp = Date.currentTimestamp() } }

    public internal(set) var phoneNumberTimestamp: UInt64

    public struct Striga: Codable, Equatable {
        public var userId: String? { didSet { userIdTimestamp = Date.currentTimestamp() } }
        public internal(set) var userIdTimestamp: UInt64

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case userIdTimestamp = "user_id_timestamp"
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: WalletMetaData.Striga.CodingKeys.self)
            try container.encodeIfPresent(userId, forKey: WalletMetaData.Striga.CodingKeys.userId)
            try container.encode(userIdTimestamp, forKey: WalletMetaData.Striga.CodingKeys.userIdTimestamp)
        }

        static func merge(lhs: Striga, rhs: Striga) -> Striga {
            Striga(
                userId: rhs.userIdTimestamp > lhs.userIdTimestamp ? rhs.userId : lhs.userId,
                userIdTimestamp: rhs.userIdTimestamp > lhs.userIdTimestamp ? rhs.userIdTimestamp : lhs.userIdTimestamp
            )
        }
    }

    public var striga: Striga

    public init(
        ethPublic: String,
        deviceName: String,
        email: String,
        authProvider: String,
        phoneNumber: String
    ) {
        let currentDate = Date.currentTimestamp()

        self.ethPublic = ethPublic

        self.deviceName = deviceName
        deviceNameTimestamp = currentDate

        self.email = email
        emailTimestamp = currentDate

        self.authProvider = authProvider
        authProviderTimestamp = currentDate

        self.phoneNumber = phoneNumber
        phoneNumberTimestamp = currentDate

        striga = Striga(userId: nil, userIdTimestamp: currentDate)
    }

    public init(
        ethPublic: String,
        deviceName: String,
        deviceNameTimestamp: UInt64,
        email: String,
        emailTimestamp: UInt64,
        authProvider: String,
        authProviderTimestamp: UInt64,
        phoneNumber: String,
        phoneNumberTimestamp: UInt64,
        striga: Striga
    ) {
        self.ethPublic = ethPublic

        self.deviceName = deviceName
        self.deviceNameTimestamp = deviceNameTimestamp

        self.email = email
        self.emailTimestamp = emailTimestamp

        self.authProvider = authProvider
        self.authProviderTimestamp = authProviderTimestamp

        self.phoneNumber = phoneNumber
        self.phoneNumberTimestamp = phoneNumberTimestamp

        self.striga = striga
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let initialDate: UInt64 = 0

        let decodedEthPublic = try container.decodeIfPresent(String.self, forKey: .ethPublic)
        if let decodedEthPublic {
            ethPublic = decodedEthPublic
        } else if let userInfoEthPublic = decoder.userInfo[Self.ethPublicInfoKey] as? String {
            ethPublic = userInfoEthPublic
        } else {
            throw DecodingError.keyNotFound(
                Self.CodingKeys.ethPublic,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Ethereum public is not available in json and in user info"
                )
            )
        }

        deviceName = try container.decode(String.self, forKey: .deviceName)
        deviceNameTimestamp = try container.decodeIfPresent(UInt64.self, forKey: .deviceNameTimestamp) ?? initialDate
        email = try container.decode(String.self, forKey: .email)
        emailTimestamp = try container.decodeIfPresent(UInt64.self, forKey: .emailTimestamp) ?? initialDate
        authProvider = try container.decode(String.self, forKey: .authProvider)
        authProviderTimestamp = try container
            .decodeIfPresent(UInt64.self, forKey: .authProviderTimestamp) ?? initialDate
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        phoneNumberTimestamp = try container.decodeIfPresent(UInt64.self, forKey: .phoneNumberTimestamp) ?? initialDate

        striga = try container.decodeIfPresent(Striga.self, forKey: .striga)
            ?? .init(userId: nil, userIdTimestamp: initialDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ethPublic, forKey: .ethPublic)

        try container.encode(deviceName, forKey: .deviceName)
        try container.encode(deviceNameTimestamp, forKey: .deviceNameTimestamp)

        try container.encode(email, forKey: .email)
        try container.encode(emailTimestamp, forKey: .emailTimestamp)

        try container.encode(authProvider, forKey: .authProvider)
        try container.encode(authProviderTimestamp, forKey: .authProviderTimestamp)

        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(phoneNumberTimestamp, forKey: .phoneNumberTimestamp)

        try container.encode(striga, forKey: .striga)
    }

    enum CodingKeys: String, CodingKey {
        case ethPublic = "eth_public"
        case deviceName = "device_name"
        case deviceNameTimestamp = "device_name_timestamp"
        case email
        case emailTimestamp = "email_timestamp"
        case authProvider = "auth_provider"
        case authProviderTimestamp = "auth_provider_timestamp"
        case phoneNumber = "phone_number"
        case phoneNumberTimestamp = "phone_number_timestamp"
        case striga
    }

    /// Encrypt metadata using seed phrase
    ///
    /// - Parameter seedPhrase:
    /// - Returns: Base64 encrypted metadata
    /// - Throws:
    public func encrypt(seedPhrase: String) throws -> String {
        let metaDataJson = try serialize()
        let encryptedMetadataRaw = try Crypto.encryptMetadata(seedPhrase: seedPhrase, data: metaDataJson)
        guard let result = try String(data: JSONEncoder().encode(encryptedMetadataRaw), encoding: .utf8) else {
            throw OnboardingError.encodingError("metadata")
        }
        return result
    }

    /// Decrypt metadata using seed phrase
    public static func decrypt(ethAddress: String, seedPhrase: String, data: String) throws -> Self {
        let encryptedMetadata = try JSONDecoder()
            .decode(Crypto.EncryptedMetadata.self, from: Data(data.utf8))
        let metadataRaw = try Crypto.decryptMetadata(
            seedPhrase: seedPhrase,
            encryptedMetadata: encryptedMetadata
        )

        return try Self.deserialize(data: metadataRaw, ethAddress: ethAddress)
    }

    public func serialize() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        return try encoder.encode(self)
    }

    public static func deserialize(data: Data, ethAddress: String) throws -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.userInfo[WalletMetaData.ethPublicInfoKey] = ethAddress

        return try decoder.decode(WalletMetaData.self, from: data)
    }
}

public extension WalletMetaData {
    enum Error: Swift.Error {
        case differentWalletMetadata
    }

    static func merge<T>(
        _ lhs: WalletMetaData,
        _ rhs: WalletMetaData,
        _ value: KeyPath<WalletMetaData, T>,
        _ date: KeyPath<WalletMetaData, UInt64>
    ) -> (T, UInt64) {
        if rhs[keyPath: date] > lhs[keyPath: date] {
            return (rhs[keyPath: value], rhs[keyPath: date])
        } else {
            return (lhs[keyPath: value], lhs[keyPath: date])
        }
    }

    static func merge(lhs: WalletMetaData, rhs: WalletMetaData) throws -> WalletMetaData {
        guard lhs.ethPublic == rhs.ethPublic else {
            throw Error.differentWalletMetadata
        }

        let deviceName = WalletMetaData.merge(lhs, rhs, \.deviceName, \.deviceNameTimestamp)
        let email = WalletMetaData.merge(lhs, rhs, \.email, \.emailTimestamp)
        let authProvider = WalletMetaData.merge(lhs, rhs, \.authProvider, \.authProviderTimestamp)
        let phoneNumber = WalletMetaData.merge(lhs, rhs, \.phoneNumber, \.phoneNumberTimestamp)
        let striga = Striga.merge(lhs: lhs.striga, rhs: rhs.striga)

        return WalletMetaData(
            ethPublic: lhs.ethPublic,

            deviceName: deviceName.0,
            deviceNameTimestamp: deviceName.1,

            email: email.0,
            emailTimestamp: email.1,

            authProvider: authProvider.0,
            authProviderTimestamp: authProvider.1,

            phoneNumber: phoneNumber.0,
            phoneNumberTimestamp: phoneNumber.1,

            striga: striga
        )
    }
}

private extension Date {
    static func currentTimestamp() -> UInt64 {
        Date().secondsSince1970
    }

    var secondsSince1970: UInt64 {
        UInt64(timeIntervalSince1970)
    }
}
