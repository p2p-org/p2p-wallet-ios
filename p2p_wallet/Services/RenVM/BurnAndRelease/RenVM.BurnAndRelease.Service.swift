//
//  RenVM.BurnAndRelease.Service.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol RenVMBurnAndReleaseServiceType {
    func burn(recipient: String, amount: UInt64) -> Single<String>
}

extension RenVM.BurnAndRelease {
    class Service: RenVMBurnAndReleaseServiceType {
        // MARK: - Constants
        private let mintTokenSymbol = "BTC"
        private let version = "1"
        private let disposeBag = DisposeBag()
        
        // MARK: - Dependencies
        private let rpcClient: RenVMRpcClientType
        private let solanaClient: RenVMSolanaAPIClientType
        private let account: SolanaSDK.Account
        private let transactionStorage: RenVMBurnAndReleaseTransactionStorageType
        private let transactionHandler: TransactionHandler
        
        // MARK: - Properties
        private var releasingTxs = [BurnDetails]()
        private let burnQueue = DispatchQueue(label: "burnQueue", qos: .background)
        private lazy var scheduler = ConcurrentDispatchQueueScheduler(queue: burnQueue)
        
        // MARK: - Subjects
        private var burnAndReleaseSubject: LoadableRelay<RenVM.BurnAndRelease>
        
        init(
            rpcClient: RenVMRpcClientType,
            solanaClient: RenVMSolanaAPIClientType,
            account: SolanaSDK.Account,
            transactionStorage: RenVMBurnAndReleaseTransactionStorageType,
            transactionHandler: TransactionHandler
        ) {
            self.rpcClient = rpcClient
            self.solanaClient = solanaClient
            self.account = account
            self.transactionStorage = transactionStorage
            self.transactionHandler = transactionHandler
            self.burnAndReleaseSubject = .init(
                request: .error(RenVM.Error.unknown)
            )
            
            bind()
            reload()
        }
        
        func bind() {
            burnAndReleaseSubject.request = RenVM.SolanaChain.load(
                client: rpcClient,
                solanaClient: solanaClient
            )
                .observe(on: scheduler)
                .map {[weak self] solanaChain in
                    guard let self = self else {throw RenVM.Error.unknown}
                    return .init(
                        rpcClient: self.rpcClient,
                        chain: solanaChain,
                        mintTokenSymbol: self.mintTokenSymbol,
                        version: self.version,
                        burnTo: "Bitcoin"
                    )
                }
            
            transactionStorage.burnTransactionObservable()
                .observe(on: scheduler)
                .map {$0.filter {[weak self] in self?.releasingTxs.contains($0) == false}}
                .subscribe(onNext: {[weak self] burnDetails in
                    for detail in burnDetails {
                        self?.release(detail)
                    }
                })
                .disposed(by: disposeBag)
        }
        
        func reload() {
            burnAndReleaseSubject.reload()
        }
        
        func burn(recipient: String, amount: UInt64) -> Single<String> {
            getBurnAndRelease()
                .flatMap {[weak self] burnAndRelease -> Single<BurnDetails> in
                    guard let self = self else {throw RenVM.Error.unknown}
                    return burnAndRelease.submitBurnTransaction(
                        account: self.account.publicKey.data,
                        amount: String(amount),
                        recipient: recipient,
                        signer: self.account.secretKey
                    )
                }
                .map { [weak self] burnDetails in
                    guard let self = self else {throw RenVM.Error.unknown}
                    self.transactionStorage.setSubmitedBurnTransaction(burnDetails)
                    return burnDetails.confirmedSignature
                }
        }
        
        private func release(_ detail: BurnDetails) {
            if !releasingTxs.contains(detail) {
                releasingTxs.append(detail)
            }
            
            requestReleasing(detail)
                .subscribe(onSuccess: {[weak self] _ in
                    guard let self = self else {return}
                    self.releasingTxs.removeAll(where: {$0.confirmedSignature == detail.confirmedSignature})
                    self.transactionStorage.releaseSubmitedBurnTransaction(detail)
                }, onFailure: {[weak self] _ in
                    guard let self = self else {return}
                    self.releasingTxs.removeAll(where: {$0.confirmedSignature == detail.confirmedSignature})
                })
                .disposed(by: disposeBag)
        }
        
        private func requestReleasing(_ detail: BurnDetails) -> Single<String> {
            getBurnAndRelease()
                .flatMap {burnAndRelease -> Single<String> in
                    let state = try burnAndRelease.getBurnState(burnDetails: detail)
                    return burnAndRelease.release(state: state, details: detail)
                }
                .catch {_ in
                    // retry after 3 sec
                    Single<Void>.just(())
                        .delay(.seconds(3), scheduler: self.scheduler)
                        .flatMap {[weak self] in
                            guard let self = self else {throw RenVM.Error.unknown}
                            return self.requestReleasing(detail)
                        }
                }
        }
        
        private func getBurnAndRelease() -> Single<RenVM.BurnAndRelease> {
            if burnAndReleaseSubject.state != .loaded || burnAndReleaseSubject.state != .loading
            {
                burnAndReleaseSubject.reload()
            }
            
            return burnAndReleaseSubject.stateObservable
                .skip(while: {$0 != .loaded && !$0.isError})
                .filter {state in
                    switch state {
                    case .error(_):
                        throw RenVM.Error("Could not initialize burn and release service")
                    default:
                        return true
                    }
                }
                .map {[weak self] _ -> RenVM.BurnAndRelease in
                    guard let self = self, let value = self.burnAndReleaseSubject.value
                    else {throw RenVM.Error.unknown}
                    return value
                }
                .take(1)
                .asSingle()
        }
    }
}
