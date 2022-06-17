//
//  FeeService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol FeeServiceType: AnyObject {
    var apiClient: SolanaAPIClient { get }
    var lamportsPerSignature: Lamports? { get set }
    var minimumBalanceForRenExemption: Lamports? { get set }
}

extension FeeServiceType {
    func load() -> Completable {
        Completable.async { [weak self] in
            guard let self = self else { return }
            let (lps, mbr) = try await(
                self.apiClient.getFees(commitment: nil).feeCalculator?.lamportsPerSignature,
                self.apiClient.getMinimumBalanceForRentExemption(span: AccountInfo.BUFFER_LENGTH)
            )
            self.lamportsPerSignature = lps
            self.minimumBalanceForRenExemption = mbr
        }
    }
}

class FeeService: FeeServiceType {
    @Injected var apiClient: SolanaAPIClient
    var lamportsPerSignature: Lamports?
    var minimumBalanceForRenExemption: Lamports?
}
