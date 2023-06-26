// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import SolanaSwift

extension SolanaAPIClient {
    public func getRelayAccountStatus(_ address: String) async throws -> RelayAccountStatus {
        let account: BufferInfo<EmptyInfo>? = try await getAccountInfo(account: address)
        guard let account = account else { return .notYetCreated }
        return .created(balance: account.lamports)
    }

    /// Retrieves associated SPL Token address for ``address``.
    ///
    /// - Returns: The associated address.
    internal func getAssociatedSPLTokenAddress(for address: PublicKey, mint: PublicKey) async throws -> PublicKey {
        let account: BufferInfo<AccountInfo>? = try? await getAccountInfo(account: address.base58EncodedString)

        // The account doesn't exists
        if account == nil {
            return try PublicKey.associatedTokenAddress(walletAddress: address, tokenMintAddress: mint)
        }

        // The account is already token account
        if account?.data.mint == mint {
            return address
        }

        // The native account
        guard account?.owner != SystemProgram.id.base58EncodedString else {
            throw FeeRelayerError.wrongAddress
        }
        return try PublicKey.associatedTokenAddress(walletAddress: address, tokenMintAddress: mint)
    }
    
    internal func isAccountExists(_ address: PublicKey) async throws -> Bool {
        let account: BufferInfo<EmptyInfo>? = try await getAccountInfo(account: address.base58EncodedString)
        return account != nil
    }
}
