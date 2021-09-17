//
//  RenVMService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol RenVMServiceType {
    var isLoadingDriver: Driver<Bool> {get}
    var errorDriver: Driver<String?> {get}
    var conditionAcceptedDriver: Driver<Bool> {get}
    var addressDriver: Driver<String?> {get}
    
    func reload()
    func acceptConditionAndLoadAddress()
    func expireCurrentSession()
    func getSessionEndDate() -> Date?
    func getCurrentAddress() -> String?
}

class RenVMService {
    // MARK: - Constants
    private let mintTokenSymbol = "BTC"
    private let version = "1"
    private let disposeBag = DisposeBag()
    
    // MARK: - Dependencies
    private let rpcClient: RenVMRpcClientType
    private let solanaClient: RenVMSolanaAPIClientType
    private let destinationAddress: SolanaSDK.PublicKey
    private let sessionStorage: RenVMSessionStorageType
    
    // MARK: - Properties
    private var loadingDisposable: Disposable?
    private var lockAndMint: RenVM.LockAndMint?
    
    // MARK: - Subjects
    private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
    private let errorSubject = BehaviorRelay<String?>(value: nil)
    private let addressSubject = BehaviorRelay<String?>(value: nil)
    private let conditionAcceptedSubject = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initializers
    init(
        rpcClient: RenVMRpcClientType,
        solanaClient: RenVMSolanaAPIClientType,
        destinationAddress: SolanaSDK.PublicKey
    ) {
        self.rpcClient = rpcClient
        self.solanaClient = solanaClient
        self.destinationAddress = destinationAddress
        
        reload()
    }
    
    func reload() {
        // clear old values
        isLoadingSubject.accept(false)
        errorSubject.accept(nil)
        conditionAcceptedSubject.accept(false)
        addressSubject.accept(nil)
        
        // if session exists, condition accepted, load session
        if sessionStorage.loadSession() != nil {
            acceptConditionAndLoadAddress()
        }
    }
    
    func acceptConditionAndLoadAddress() {
        conditionAcceptedSubject.accept(true)
        loadSession(savedSession: sessionStorage.loadSession())
    }
    
    private func loadSession(savedSession: RenVM.Session?) {
        // set loading
        isLoadingSubject.accept(true)
        
        loadingDisposable?.dispose()
        
        // request
        loadingDisposable = RenVM.SolanaChain.load(
            client: rpcClient,
            solanaClient: solanaClient
        )
            .observe(on: MainScheduler.instance)
            .flatMap {[weak self] solanaChain -> Single<Data> in
                guard let self = self else {throw RenVM.Error.unknown}
                
                // create lock and mint
                self.lockAndMint = try .init(
                    rpcClient: self.rpcClient,
                    chain: solanaChain,
                    mintTokenSymbol: self.mintTokenSymbol,
                    version: self.version,
                    destinationAddress: self.destinationAddress.data,
                    session: savedSession
                )
                
                // save session
                if savedSession == nil {
                    self.sessionStorage.saveSession(self.lockAndMint!.session)
                }
                
                // generate address
                return self.lockAndMint!.generateGatewayAddress()
            }
            .map {Base58.encode($0.bytes)}
            .subscribe(on: MainScheduler.instance)
            .subscribe(onSuccess: {[weak self] address in
                self?.isLoadingSubject.accept(false)
                self?.addressSubject.accept(address)
            }, onFailure: {[weak self] error in
                self?.isLoadingSubject.accept(false)
                self?.errorSubject.accept(error.readableDescription)
            })
    }
    
    func expireCurrentSession() {
        sessionStorage.expireCurrentSession()
        reload()
    }
}

extension RenVMService: RenVMServiceType {
    
}
