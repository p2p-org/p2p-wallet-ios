// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

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

public struct SignUpResult: Codable {
    public let privateSOL: String
    public let reconstructedETH: String
    public let deviceShare: String
    public let customShare: String
    
    /// Ecies meta data
    public let metaData: String
}

public struct SignInResult: Codable {
    public let privateSOL: String
    public let reconstructedETH: String
}
