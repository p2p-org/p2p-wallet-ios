// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

/// APIClient protocol for fee relayer
public protocol FeeRelayerAPIClient {
    
    /// Current FeeRelayer's version
    var version: Int { get }
    
    /// Get fee payer account's public key
    /// - Returns: Public key as String
    func getFeePayerPubkey() async throws -> String
    
    /// Get fee token data
    func feeTokenData(mint: String) async throws -> FeeTokenData
    
    /// Get free fee limits for current user
    /// - Parameter authority: user's authority
    /// - Returns: current user's usage limit
    func getFreeFeeLimits(for authority: String) async throws -> FeeLimitForAuthorityResponse
    
    /// Get free fee limits for current user
    /// - Parameter authority: user's authority
    /// - Returns: current user's usage limit
    @available(*, deprecated, renamed: "getFreeFeeLimits")
    func requestFreeFeeLimits(for authority: String) async throws -> FeeLimitForAuthorityResponse
    
    /// Send transaction to fee relayer server to process
    /// - Parameter requestType: FeeRelayer's Request Type
    /// - Returns: signature, can be confirmed or signature of fee payer account that can be added to process later by client
    func sendTransaction(_ requestType: RequestType) async throws -> String
}
