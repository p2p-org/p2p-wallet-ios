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
    private let account: SolanaSDK.Account
    private let sessionStorage: RenVMSessionStorageType
    
    // MARK: - Properties
    private var loadingDisposable: Disposable?
    private var observingTxStreamDisposable: Disposable?
    private var lockAndMint: RenVM.LockAndMint?
    private let mintQueue = DispatchQueue(label: "mintQueue", qos: .background)
    private lazy var scheduler = SerialDispatchQueueScheduler(queue: mintQueue, internalSerialQueueName: "mintQueue")
    private lazy var handlingTxIds = [String]()
    
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
            .map {[weak self] array -> TxDetail in
                guard let self = self else {throw RenVM.Error.unknown}
                return array.filter {!self.sessionStorage.isMinted(txid: $0.txid) && !self.handlingTxIds.contains($0.txid)}
            }
            .subscribe(onSuccess: { [weak self] details in
                guard !details.isEmpty else {return}
                Logger.log(message: "renBTC event: \(details)", event: .info)
                
                for detail in details {
                    self?.handlingTxIds.append(detail.txid)
                    try? self?.mint(response: response, txDetail: detail)
                }
            }, onFailure: { error in
                Logger.log(message: "renBTC event error: \(error)", event: .error)
            })
            .disposed(by: disposeBag)
    }
    
    private func mint(response: RenVM.LockAndMint.GatewayAddressResponse, txDetail: TxDetailElement) throws {
        
        prepareMintRequest(response: response, txDetail: txDetail)
            .subscribe(onSuccess: {[weak self] signature in
                Logger.log(message: "renBTC event mint signature: \(signature)", event: .info)
                self?.sessionStorage.setAsMinted(txid: txDetail.txid)
                
            }, onFailure: {[weak self] error in
                guard let self = self else {return}
                Logger.log(message: "renBTC event mint error: \(error), isSubmited: \(self.sessionStorage.isSubmited(txid: txDetail.txid)), isMinted: \(self.sessionStorage.isMinted(txid: txDetail.txid))", event: .error)
            })
            .disposed(by: disposeBag)
    }
    
    private func prepareMintRequest(response: RenVM.LockAndMint.GatewayAddressResponse, txDetail: TxDetailElement) -> Single<String>
    {
        guard let lockAndMint = lockAndMint else {
            return .error(RenVM.Error.unknown)
        }
        
        let state: RenVM.State
        
        do {
            state = try lockAndMint.getDepositState(
                transactionHash: txDetail.txid,
                txIndex: String(txDetail.vout),
                amount: String(txDetail.value),
                sendTo: response.sendTo,
                gHash: response.gHash,
                gPubkey: response.gPubkey
            )
        } catch {
            return .error(error)
        }
        
        let submitMintRequest: Completable
        
        // the transaction hasn't already been submitted
        if sessionStorage.isSubmited(txid: txDetail.txid) {
            submitMintRequest = .empty()
        } else {
            submitMintRequest = lockAndMint.submitMintTransaction(state: state)
                .asCompletable()
                .do(onCompleted: { [weak self] in
                    self?.sessionStorage.setAsSubmited(txid: txDetail.txid)
                })
        }
        
        return submitMintRequest
            .andThen(
                lockAndMint.mint(state: state, signer: self.account.secretKey)
            )
            .catch {[weak self] error in
                guard let self = self else {throw RenVM.Error.unknown}
                if let error = error as? RenVM.Error,
                   error == .paramsMissing
                {
                    return Single<Void>.just(())
                        .delay(.seconds(3), scheduler: self.scheduler)
                        .flatMap {[weak self] in
                            guard let self = self else {throw RenVM.Error.unknown}
                            return self.prepareMintRequest(response: response, txDetail: txDetail)
                        }
                }
                throw error
            }
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
