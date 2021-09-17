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
    private var observingTxStreamDisposable: Disposable?
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
        destinationAddress: SolanaSDK.PublicKey,
        sessionStorage: RenVMSessionStorageType
    ) {
        self.rpcClient = rpcClient
        self.solanaClient = solanaClient
        self.destinationAddress = destinationAddress
        self.sessionStorage = sessionStorage
        
        reload()
    }
    
    func reload() {
        // clear old values
        isLoadingSubject.accept(false)
        errorSubject.accept(nil)
        conditionAcceptedSubject.accept(false)
        addressSubject.accept(nil)
        loadingDisposable?.dispose()
        observingTxStreamDisposable?.dispose()
        
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
                self?.observeTxStreamAndMint()
            }, onFailure: {[weak self] error in
                self?.isLoadingSubject.accept(false)
                self?.errorSubject.accept(error.readableDescription)
            })
    }
    
    func expireCurrentSession() {
        sessionStorage.expireCurrentSession()
        reload()
    }
    
    private func observeTxStreamAndMint() {
        // cancel previous observing
        observingTxStreamDisposable?.dispose()
        
        // create new observing with new address
        guard let address = addressSubject.value
        else {return}
        
        // do request each 3 seconds in background
        observingTxStreamDisposable = Timer.observable(
            seconds: 3,
            scheduler: ConcurrentDispatchQueueScheduler(qos: .background)
        )
            .flatMap {[weak self] _ -> Single<Data> in
                guard let self = self else {return .just(Data())}
                var url = "https://blockstream.info"
                if self.rpcClient.network.isTestnet {
                    url += "/testnet"
                }
                url += "/\(address)/utxo"
                return URLSession(configuration: .default)
                    .rx.data(request: try .init(url: "", method: .get))
                    .take(1).asSingle()
            }
            .map {(try? JSONDecoder().decode(TxDetail.self, from: $0)) ?? []}
            .catchAndReturn([])
            .map {$0.filter {$0.status.confirmed == true}}
            .observe(on: ConcurrentMainScheduler.instance)
            .subscribe(onNext: {[weak self] details in
                Logger.log(message: "Received renBTC transactions: \(details)", event: .info)
                guard let self = self, !details.isEmpty else {return}
                for detail in details {
                    guard let _ = try? self.lockAndMint?.getDepositState(transactionHash: detail.txid, txIndex: String(detail.vout), amount: String(detail.value))
                    else {
                        continue
                    }
                    
                    self.lockAndMint?.mint(signer: <#T##Data#>)
                }
            })
    }
}

extension RenVMService: RenVMServiceType {
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }
    
    var errorDriver: Driver<String?> {
        errorSubject.asDriver()
    }
    
    var conditionAcceptedDriver: Driver<Bool> {
        conditionAcceptedSubject.asDriver()
    }
    
    var addressDriver: Driver<String?> {
        addressSubject.asDriver()
    }
    
    func getSessionEndDate() -> Date? {
        sessionStorage.loadSession()?.endAt
    }
    
    func getCurrentAddress() -> String? {
        addressSubject.value
    }
}

// MARK: - TxDetailElement
private struct TxDetailElement: Codable {
    let txid: String
    let vout: UInt64
    let status: Status
    let value: UInt64
}

// MARK: - Status
private struct Status: Codable {
    let confirmed: Bool
    let blockHeight: Int?
    let blockHash: String?
    let blockTime: Int?

    enum CodingKeys: String, CodingKey {
        case confirmed
        case blockHeight = "block_height"
        case blockHash = "block_hash"
        case blockTime = "block_time"
    }
}

private typealias TxDetail = [TxDetailElement]

