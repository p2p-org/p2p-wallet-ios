// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

public protocol TKeyFacade {
    func initialize() async throws
    
    func obtainTorusKey(tokenID: TokenID) async throws -> TorusKey
    
    func signUp(torusKey: TorusKey, privateInput: String) async throws -> SignUpResult
    func signIn(torusKey: TorusKey, deviceShare: String) async throws -> SignInResult
    func signIn(torusKey: TorusKey, customShare: String, encryptedMnemonic: String) async throws -> SignInResult
    func signIn(deviceShare: String, customShare: String, encryptedMnemonic: String) async throws -> SignInResult
}

struct TKeyFacadeError: Error, Codable {
    let name: String
    let code: Int
    let message: String
    let original: String?
}
