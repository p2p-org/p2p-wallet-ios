import Foundation

public struct TorusKey: Codable, Equatable {
    /// The user token id. This token id can not be used again in torus
    let tokenID: TokenID
    /// The torus key
    let value: String
}

public struct TokenID: Codable, Equatable {
    public let value: String
    public let provider: String

    public init(value: String, provider: String) {
        self.value = value
        self.provider = provider
    }
}

public typealias DeviceShare = String

public struct SignUpResult: Codable, Equatable {
    public let privateSOL: String
    public let reconstructedETH: String
    public let deviceShare: String
    public let customShare: String

    /// Ecies meta data
    public let metaData: String
}

public struct SignInResult: Codable, Equatable {
    public let privateSOL: String
    public let reconstructedETH: String
}

public struct RefreshDeviceShareResult: Codable, Equatable {
    public let share: String
}
