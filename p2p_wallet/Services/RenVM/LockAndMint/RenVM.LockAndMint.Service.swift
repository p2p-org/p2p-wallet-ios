//
//  RenVM.LockAndMint.Service.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/09/2021.
//

import Foundation
import RxAlamofire
import RxSwift
import RxCocoa

protocol RenVMLockAndMintServiceType {
    var isLoadingDriver: Driver<Bool> {get}
    var errorDriver: Driver<String?> {get}
    var conditionAcceptedDriver: Driver<Bool> {get}
    var addressDriver: Driver<String?> {get}
    var minimumTransactionAmountDriver: Driver<Loadable<Double>> {get}
    
    func reload()
    func reloadMinimumTransactionAmount()
    func acceptConditionAndLoadAddress()
    func expireCurrentSession()
    func getSessionEndDate() -> Date?
    func getCurrentAddress() -> String?
}

extension RenVM.LockAndMint {
    class Service {
        // MARK: - Constants
        private let refreshRate = 3 // in seconds, refreshing frequency
        private let mintingRate = 60 // in seconds, time between 2 minting attempts
        private let mintTokenSymbol = "BTC"
        private let version = "1"
        private let disposeBag = DisposeBag()
        
        // MARK: - Dependencies
        private let rpcClient: RenVMRpcClientType
        private let solanaClient: RenVMSolanaAPIClientType
        private let account: SolanaSDK.Account
        private let sessionStorage: RenVMLockAndMintSessionStorageType
        private let transactionHandler: TransactionHandler
        
        // MARK: - Properties
        private var loadingDisposable: Disposable?
        private var lockAndMint: RenVM.LockAndMint?
        private let mintQueue = DispatchQueue(label: "mintQueue", qos: .background)
        private lazy var scheduler = SerialDispatchQueueScheduler(queue: mintQueue, internalSerialQueueName: "mintQueue")
        
        // MARK: - Subjects
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        private let errorSubject = BehaviorRelay<String?>(value: nil)
        private let addressSubject = BehaviorRelay<String?>(value: nil)
        private let conditionAcceptedSubject = BehaviorRelay<Bool>(value: false)
        private let minimumTransactionAmountSubject: LoadableRelay<Double>
        
        // MARK: - Initializers
        init(
            rpcClient: RenVMRpcClientType,
            solanaClient: RenVMSolanaAPIClientType,
            account: SolanaSDK.Account,
            sessionStorage: RenVMLockAndMintSessionStorageType,
            transactionHandler: TransactionHandler
        ) {
            self.rpcClient = rpcClient
            self.solanaClient = solanaClient
            self.account = account
            self.sessionStorage = sessionStorage
            self.transactionHandler = transactionHandler
            self.minimumTransactionAmountSubject = .init(
                request: rpcClient.getTransactionFee(mintTokenSymbol: mintTokenSymbol)
                    .map {$0.convertToBalance(decimals: 8)}
            )
            
            reload()
            reloadMinimumTransactionAmount()
        }
        
        // MARK: - Sessions
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
        
        func reloadMinimumTransactionAmount() {
            minimumTransactionAmountSubject.reload()
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
                .observe(on: MainScheduler.instance)
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
        
        // MARK: - Processing transactions
        private var observingTxStreamDisposable: Disposable?
        private var observingProcessingTxsDisposable: Disposable?
        
        private func observeTxStreamAndMint(response: RenVM.LockAndMint.GatewayAddressResponse) {
            // cancel previous observing
            observingTxStreamDisposable?.dispose()
            observingProcessingTxsDisposable?.dispose()
            
            // refreshing
            observingTxStreamDisposable = Timer.observable(
                seconds: refreshRate,
                scheduler: scheduler
            )
                .observe(on: scheduler)
                .subscribe(onNext: { [weak self] in
                    try? self?.observeTxStatusAndMint(response: response)
                })
            
            // minting
            observingProcessingTxsDisposable = sessionStorage.processingTxsDriver
                .asObservable()
                .observe(on: scheduler)
                .subscribe(onNext: { [weak self] txs in
                    guard let self = self else {return}
                    
                    // get confirmed and submited transactions
                    let txs = txs.filter {
                        $0.status != .confirmed &&
                            $0.status != .submitted
                    }
                    
                    // mint
                    for tx in txs {
                        try? self.processConfirmedAndSubmitedTransaction(tx, response: response)
                    }
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
            
            RxAlamofire.request(request)
                .responseData()
                .take(1).asSingle()
                .map {try JSONDecoder().decode(TxDetails.self, from: $1)}
                
                // merge result to storage
                .subscribe(onSuccess: {[weak self] txs in
                    guard let self = self else {return}
                    
                    // filter out processing txs
                    let txs = txs.filter {!self.sessionStorage.isProcessing(txid: $0.txid)}
                    
                    // log
                    Logger.log(message: "renBTC event new transactions: \(txs)", event: .info)
                    
                    // save processing txs to storage
                    for tx in txs {
                        self.sessionStorage.set(tx.status.confirmed ? .confirmed: .waitingForConfirmation, for: tx)
                    }
                })
                .disposed(by: disposeBag)
        }
        
        private func processConfirmedAndSubmitedTransaction(_ tx: ProcessingTx, response: RenVM.LockAndMint.GatewayAddressResponse) throws {
            prepareRequest(response: response, tx: tx)
                .do(onSuccess: {[weak self] response in
                    Logger.log(message: "renBTC event mint response: \(response)", event: .info)
                    self?.sessionStorage.setAsMinted(tx: txDetail)

                    let amount = UInt64(response.amountOut ?? "")
                    let value = (amount ?? txDetail.value).convertToBalance(decimals: 8)
                        .toString(maximumFractionDigits: 8)
                    UIApplication.shared.showToast(message: L10n.receivingRenBTCPending(value))
                })
                .flatMap {[weak self] response -> Single<(amountOut: String?, signature: String)> in
                    guard let self = self else {throw RenVM.Error.unknown}
                    return self.transactionHandler.observeTransactionCompletion(signature: response.signature)
                        .andThen(.just(response))
                }
                .subscribe(onSuccess: { response in
                    let amount = UInt64(response.amountOut ?? "")
                    let value = (amount ?? txDetail.value).convertToBalance(decimals: 8)
                        .toString(maximumFractionDigits: 8)
                    UIApplication.shared.showToast(message: L10n.receivedRenBTC(value))
                }, onFailure: { [weak self] error in
                    guard let self = self else {return}

                    // already minted
                    if error.isAlreadyInUseSolanaError {
                        Logger.log(message: "txDetail is already minted \(txDetail)", event: .info)
                        self.sessionStorage.setAsMinted(tx: txDetail)
                    }
                    
                    // other error
                    Logger.log(message: "renBTC event mint error: \(error), isSubmited: \(self.sessionStorage.isSubmited(txid: txDetail.txid)), isMinted: \(self.sessionStorage.isMinted(txid: txDetail.txid))", event: .error)
                    
                    // remove from handling list
                    self.handlingTxIds.removeAll(where: {$0 == txDetail.txid})
                })
                .disposed(by: disposeBag)
        }
        
        private func prepareRequest(response: GatewayAddressResponse, tx: ProcessingTx) -> Single<(amountOut: String?, signature: String)>
        {
            guard let lockAndMint = lockAndMint else {
                return .error(RenVM.Error.unknown)
            }
            
            let state: RenVM.State
            
            do {
                state = try lockAndMint.getDepositState(
                    transactionHash: tx.tx.txid,
                    txIndex: String(tx.tx.vout),
                    amount: String(tx.tx.value),
                    sendTo: response.sendTo,
                    gHash: response.gHash,
                    gPubkey: response.gPubkey
                )
            } catch {
                return .error(error)
            }
            
            let submitMintRequest: Completable
            
            // submited transaction
            if tx.status == .submitted {
                submitMintRequest = .empty()
            }
            
            // confirmed (non-submited) transaction
            else {
                // set as submitting
                sessionStorage.set(.submitting, for: tx.tx)
                
                // request
                submitMintRequest = lockAndMint.submitMintTransaction(state: state)
                    .asCompletable()
                    .do(onError: {[weak self] _ in
                        // back to confirmed
                        self?.sessionStorage.set(.confirmed, for: tx.tx)
                    }, onCompleted: { [weak self] in
                        self?.sessionStorage.set(.submitted, for: tx.tx)
                    })
            }
            
            // send request
            return submitMintRequest
                .do(onCompleted: { [weak self] in
                    self?.sessionStorage.set(.minting, for: tx.tx)
                })
                .andThen(
                    lockAndMint.mint(state: state, signer: self.account.secretKey)
                        .do(onSuccess: { _ in
                            self.sessionStorage.set(.minted, for: tx.tx)
                        }, onError: {_ in
                            self.sessionStorage.set(.submitted, for: tx.tx)
                        })
                )
                .catch {[weak self] error in
                    guard let self = self else {throw RenVM.Error.unknown}
                    if let error = error as? RenVM.Error,
                       error == .paramsMissing
                    {
                        return Single<Void>.just(())
                            .delay(.seconds(self.mintingRate), scheduler: self.scheduler)
                            .flatMap {[weak self] in
                                guard let self = self else {throw RenVM.Error.unknown}
                                return self.prepareRequest(response: response, tx: tx)
                            }
                    }
                    throw error
                }
        }
    }
}

extension RenVM.LockAndMint.Service: RenVMLockAndMintServiceType {
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
    
    var minimumTransactionAmountDriver: Driver<Loadable<Double>> {
        minimumTransactionAmountSubject.asDriver()
    }
    
    func getSessionEndDate() -> Date? {
        sessionStorage.loadSession()?.endAt
    }
    
    func getCurrentAddress() -> String? {
        addressSubject.value
    }
}

extension RenVM.LockAndMint {
    // MARK: - TxDetailElement
    struct TxDetail: Codable {
        let txid: String
        let vout: UInt64
        let status: Status
        let value: UInt64
        
        struct Status: Codable {
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
    }
    typealias TxDetails = [TxDetail]
}
