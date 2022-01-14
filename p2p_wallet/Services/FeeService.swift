//
//  FeeService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - FeeAPIClient
protocol FeeAPIClient {
    func getLamportsPerSignature() -> Single<SolanaSDK.Lamports>
    func getCreatingTokenAccountFee() -> Single<UInt64>
}

extension SolanaSDK: FeeAPIClient {
    func getLamportsPerSignature() -> Single<Lamports> {
        getFees().map {$0.feeCalculator?.lamportsPerSignature}.map {$0 ?? 0}
    }
}

// MARK: - FeeService
protocol FeeServiceType: AnyObject {
    var apiClient: FeeAPIClient {get}
    var lamportsPerSignature: SolanaSDK.Lamports? {get set}
    var minimumBalanceForRenExemption: SolanaSDK.Lamports? {get set}
}

extension FeeServiceType {
    func load() -> Completable {
        Single.zip(
            apiClient.getLamportsPerSignature(),
            apiClient.getCreatingTokenAccountFee()
        )
            .do(onSuccess: { [weak self] lps, mbr in
                self?.lamportsPerSignature = lps
                self?.minimumBalanceForRenExemption = mbr
            })
            .flatMapCompletable { _ in
                .empty()
            }
    }
}

class FeeService: FeeServiceType {
    @Injected var apiClient: FeeAPIClient
    var lamportsPerSignature: SolanaSDK.Lamports?
    var minimumBalanceForRenExemption: SolanaSDK.Lamports?
}
