// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public struct WalletMetaData: Codable, Equatable {
    static let ethPublicInfoKey = CodingUserInfoKey(rawValue: "ethPublic")!

    public let ethPublic: String

    public var deviceName: String { didSet { deviceNameTimestamp = Date() } }

    public internal(set) var deviceNameTimestamp: Date

    public var email: String { didSet { emailTimestamp = Date() } }

    public internal(set) var emailTimestamp: Date

    public var authProvider: String { didSet { authProviderTimestamp = Date() } }

    public internal(set) var authProviderTimestamp: Date

    public var phoneNumber: String { didSet { phoneNumberTimestamp = Date() } }

    public internal(set) var phoneNumberTimestamp: Date

    public struct Striga: Codable, Equatable {
        public var userId: String? { didSet { userIdTimestamp = Date() } }
        public internal(set) var userIdTimestamp: Date

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case userIdTimestamp = "user_id_timestamp"
        }

        static func merge(lhs: Striga, rhs: Striga) -> Striga {
            Striga(
                userId: rhs.userIdTimestamp > lhs.userIdTimestamp ? rhs.userId : lhs.userId,
                userIdTimestamp: rhs.userIdTimestamp > lhs.userIdTimestamp ? rhs.userIdTimestamp : lhs.userIdTimestamp
            )
        }
    }

    public let striga: Striga

    public init(
        ethPublic: String,
        deviceName: String,
        email: String,
        authProvider: String,
        phoneNumber: String
    ) {
        let currentDate = Date()

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
        deviceNameTimestamp: Date,
        email: String,
        emailTimestamp: Date,
        authProvider: String,
        authProviderTimestamp: Date,
        phoneNumber: String,
        phoneNumberTimestamp: Date,
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
        let currentDate = Date()

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
        deviceNameTimestamp = try container.decodeIfPresent(Date.self, forKey: .deviceNameTimestamp) ?? currentDate
        email = try container.decode(String.self, forKey: .email)
        emailTimestamp = try container.decodeIfPresent(Date.self, forKey: .emailTimestamp) ?? currentDate
        authProvider = try container.decode(String.self, forKey: .authProvider)
        authProviderTimestamp = try container.decodeIfPresent(Date.self, forKey: .authProviderTimestamp) ?? currentDate
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        phoneNumberTimestamp = try container.decodeIfPresent(Date.self, forKey: .phoneNumberTimestamp) ?? currentDate

        striga = try container.decodeIfPresent(Striga.self, forKey: .striga)
            ?? .init(userId: nil, userIdTimestamp: currentDate)
    }

    enum CodingKeys: String, CodingKey {
        case ethPublic = "eth_public"
        case deviceName = "device_name"
        case deviceNameTimestamp = "device_name_timestamp3"
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        let metaDataJson = try encoder.encode(self)
        let encryptedMetadataRaw = try Crypto.encryptMetadata(seedPhrase: seedPhrase, data: metaDataJson)
        guard let result = String(data: try JSONEncoder().encode(encryptedMetadataRaw), encoding: .utf8) else {
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.userInfo[WalletMetaData.ethPublicInfoKey] = ethAddress

        return try decoder.decode(WalletMetaData.self, from: metadataRaw)
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
        _ date: KeyPath<WalletMetaData, Date>
    ) -> (T, Date) {
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

        return WalletMetaData(
            ethPublic: lhs.ethPublic,

            deviceName: WalletMetaData.merge(lhs, rhs, \.deviceName, \.deviceNameTimestamp).0,
            deviceNameTimestamp: WalletMetaData.merge(lhs, rhs, \.deviceName, \.deviceNameTimestamp).1,

            email: WalletMetaData.merge(lhs, rhs, \.email, \.emailTimestamp).0,
            emailTimestamp: WalletMetaData.merge(lhs, rhs, \.email, \.emailTimestamp).1,

            authProvider: WalletMetaData.merge(lhs, rhs, \.authProvider, \.authProviderTimestamp).0,
            authProviderTimestamp: WalletMetaData.merge(lhs, rhs, \.authProvider, \.authProviderTimestamp).1,

            phoneNumber: WalletMetaData.merge(lhs, rhs, \.phoneNumber, \.phoneNumberTimestamp).0,
            phoneNumberTimestamp: WalletMetaData.merge(lhs, rhs, \.phoneNumber, \.phoneNumberTimestamp).1,

            striga: Striga.merge(lhs: lhs.striga, rhs: rhs.striga)
        )
    }
}
