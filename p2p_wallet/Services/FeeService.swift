//
//  FeeService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import Resolver
import SolanaSwift

protocol FeeServiceType: AnyObject {
    var apiClient: SolanaAPIClient { get }
    var lamportsPerSignature: Lamports? { get set }
    var minimumBalanceForRenExemption: Lamports? { get set }
}

extension FeeServiceType {
    func load() async throws {
        let (lps, mbr) = try await(
            apiClient.getFees(commitment: nil).feeCalculator?.lamportsPerSignature,
            apiClient.getMinimumBalanceForRentExemption(span: AccountInfo.BUFFER_LENGTH)
        )
        lamportsPerSignature = lps
        minimumBalanceForRenExemption = mbr
    }
}

class FeeService: FeeServiceType {
    @Injected var apiClient: SolanaAPIClient
    var lamportsPerSignature: Lamports?
    var minimumBalanceForRenExemption: Lamports?
}
