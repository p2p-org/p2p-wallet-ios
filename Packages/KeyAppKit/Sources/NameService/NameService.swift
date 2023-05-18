// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

public protocol NameService {
    /// Resolve user name by account's public key.
    ///
    /// - Parameter owner: public key
    /// - Returns: user name
    func getName(_ owner: String, withTLD: Bool) async throws -> String?

    /// Resolve first matched public key by username.
    ///
    /// - Parameter name: user name
    /// - Returns: account's public key
    func getOwnerAddress(_ name: String) async throws -> String?

    /// Resolve all public keys by name.
    ///
    /// - Parameter name: username
    /// - Returns: Array of ``NameRecord``
    func getOwners(_ name: String) async throws -> [NameRecord]

    /// Bind name to public key
    ///
    /// - Parameters:
    ///   - name: username
    ///   - publicKey: account's public key
    ///   - privateKey: account's secret key
    /// - Returns: Transaction signature for binding username with public key
    func create(name: String, publicKey: String, privateKey: Data) async throws -> CreateNameTransaction

    // TODO: Tech debt, don't delete. This method will be used after release for users not authorized with web3auth
    /// Bind name to public key
    ///
    /// - Parameters:
    ///   - name: username
    ///   - params: binding configurations
    /// - Returns: Transaction signature for binding username with public key
    func post(name: String, params: PostParams) async throws -> PostResponse
}

extension NameService {
    /// Check if the name is available for binding.
    public func isNameAvailable(_ name: String) async throws -> Bool {
        try await getOwnerAddress(name) == nil
    }
}
