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
    // MARK: - Nested type
    enum TxStatus: Comparable, Equatable {
        case submiting, submited, minting, minted
        var isProcessing: Bool {
            self == .submiting || self == .minting
        }
    }
    
    // MARK: - Constants
    private let mintTokenSymbol = "BTC"
    private let version = "1"
    private let disposeBag = DisposeBag()
    
    // MARK: - Dependencies
    private let rpcClient: RenVMRpcClientType
    private let solanaClient: RenVMSolanaAPIClientType
    private let account: SolanaSDK.Account
    private let sessionStorage: RenVMSessionStorageType
    
    // MARK: - Properties
    private var loadingDisposable: Disposable?
    private var observingTxStreamDisposable: Disposable?
    private var lockAndMint: RenVM.LockAndMint?
    private let mintQueue = DispatchQueue(label: "mintQueue", qos: .background)
    private lazy var scheduler = SerialDispatchQueueScheduler(queue: mintQueue, internalSerialQueueName: "mintQueue")
    
    // MARK: - Subjects
    private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
    private let errorSubject = BehaviorRelay<String?>(value: nil)
    private let addressSubject = BehaviorRelay<String?>(value: nil)
    private let conditionAcceptedSubject = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initializers
    init(
        rpcClient: RenVMRpcClientType,
        solanaClient: RenVMSolanaAPIClientType,
        account: SolanaSDK.Account,
        sessionStorage: RenVMSessionStorageType
    ) {
        self.rpcClient = rpcClient
        self.solanaClient = solanaClient
        self.account = account
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
        if let session = sessionStorage.loadSession() {
            if Date() >= session.endAt {
                expireCurrentSession()
            } else {
                acceptConditionAndLoadAddress()
            }
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
            .flatMap {[weak self] solanaChain -> Single<RenVM.LockAndMint.GatewayAddressResponse> in
                guard let self = self else {throw RenVM.Error.unknown}
                
                // create lock and mint
                self.lockAndMint = try .init(
                    rpcClient: self.rpcClient,
                    chain: solanaChain,
                    mintTokenSymbol: self.mintTokenSymbol,
                    version: self.version,
                    destinationAddress: self.account.publicKey.data,
                    session: savedSession
                )
                
                // save session
                if savedSession == nil {
                    self.sessionStorage.saveSession(self.lockAndMint!.session)
                }
                
                // generate address
                return self.lockAndMint!.generateGatewayAddress()
            }
            .subscribe(on: MainScheduler.instance)
            .subscribe(onSuccess: {[weak self] response in
                self?.isLoadingSubject.accept(false)
                self?.addressSubject.accept(Base58.encode(response.gatewayAddress.bytes))
                self?.observeTxStreamAndMint(response: response)
            }, onFailure: {[weak self] error in
                self?.isLoadingSubject.accept(false)
                self?.errorSubject.accept(error.readableDescription)
            })
    }
    
    func expireCurrentSession() {
        sessionStorage.expireCurrentSession()
        reload()
    }
    
    private func observeTxStreamAndMint(response: RenVM.LockAndMint.GatewayAddressResponse) {
        // cancel previous observing
        observingTxStreamDisposable?.dispose()
        
        // do request each 3 seconds in background
        observingTxStreamDisposable = Timer.observable(
            seconds: 3,
            scheduler: scheduler
        )
            .observe(on: scheduler)
            .subscribe(onNext: { [weak self] in
                try? self?.observeTxStatusAndMint(response: response)
            })
    }
    
    private func observeTxStatusAndMint(response: RenVM.LockAndMint.GatewayAddressResponse) throws {
        guard let endAt = getSessionEndDate(), Date() < endAt
        else {
            expireCurrentSession()
            return
        }
        
        guard let address = addressSubject.value else {return}
        
        var url = "https://blockstream.info"
        if self.rpcClient.network.isTestnet {
            url += "/testnet"
        }
        url += "/api/address/\(address)/utxo"
        let request = try URLRequest(url: url, method: .get)
        
        URLSession(configuration: .default)
            .rx.data(request: request)
            .take(1).asSingle()
            .map {try JSONDecoder().decode(TxDetail.self, from: $0)}
            .map {$0.filter {$0.status.confirmed == true}}
            .map {$0.filter {Defaults.renVMTxs[$0.txid] != .minted}}
            .subscribe(onSuccess: { [weak self] details in
                Logger.log(message: "renBTC event: \(details)", event: .info)
                
                for detail in details {
                    try? self?.mint(response: response, txDetail: detail)
                }
            }, onFailure: { error in
                Logger.log(message: "renBTC event error: \(error)", event: .error)
            })
            .disposed(by: disposeBag)
    }
    
    private func mint(response: RenVM.LockAndMint.GatewayAddressResponse, txDetail: TxDetailElement) throws {
        
        guard let lockAndMint = lockAndMint
        else {
            return
        }
        
        // prevent dupplicating
        if let status = Defaults.renVMTxs[txDetail.txid],
           status.isProcessing
        {
            return
        }
        
        let state = try lockAndMint.getDepositState(
            transactionHash: txDetail.txid,
            txIndex: String(txDetail.vout),
            amount: String(txDetail.value),
            sendTo: response.sendTo,
            gHash: response.gHash,
            gPubkey: response.gPubkey
        )
        
        let submitMintRequest: Completable
        
        // the transaction hasn't already been submitted
        if (Defaults.renVMTxs[txDetail.txid] ?? .submiting) < .submited {
            Defaults.renVMTxs[txDetail.txid] = .submiting
            submitMintRequest = lockAndMint.submitMintTransaction(state: state)
                .asCompletable()
        }
        
        // the transaction has been submitted
        else {
            submitMintRequest = .empty()
        }
        
        submitMintRequest
            .do(onError: {_ in
                // error submitting
                Defaults.renVMTxs[txDetail.txid] = nil
            }, onCompleted: {
                // completed, forward to minting
                Defaults.renVMTxs[txDetail.txid] = .minting
            })
            .andThen(
                lockAndMint.mint(state: state, signer: self.account.secretKey)
                    .do(
                        onError: { _ in
                            // error, back to minting in next request
                            Defaults.renVMTxs[txDetail.txid] = .submited
                        }
                    )
            )
            .observe(on: scheduler)
            .subscribe(onSuccess: {signature in
                Logger.log(message: "renBTC event mint signature: \(signature)", event: .info)
                Defaults.renVMTxs[txDetail.txid] = .minted
                
            }, onFailure: { error in
                Logger.log(message: "renBTC event mint error: \(error), txStatus: \(String(describing: Defaults.renVMTxs[txDetail.txid]))", event: .error)
            })
            .disposed(by: disposeBag)
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
