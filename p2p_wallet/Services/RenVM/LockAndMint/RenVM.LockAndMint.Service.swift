//
//  RenVM.LockAndMint.Service.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/09/2021.
//

import Foundation
import RenVMSwift
import Resolver
import RxAlamofire
import RxCocoa
import RxSwift

protocol RenVMLockAndMintServiceType {
    var isLoadingDriver: Driver<Bool> { get }
    var errorDriver: Driver<String?> { get }
    var conditionAcceptedDriver: Driver<Bool> { get }
    var addressDriver: Driver<String?> { get }
    var minimumTransactionAmountDriver: Driver<Loadable<Double>> { get }
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> { get }

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
        @Injected private var notificationsService: NotificationsServiceType

        // MARK: - Properties

        private var loadingDisposable: Disposable?
        private var lockAndMint: RenVM.LockAndMint?
        private let mintQueue = DispatchQueue(label: "mintQueue", qos: .background)
        private lazy var scheduler = SerialDispatchQueueScheduler(
            queue: mintQueue,
            internalSerialQueueName: "mintQueue"
        )
        private var observingTxStreamDisposable: Disposable?

        // MARK: - Subjects

        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        private let errorSubject = BehaviorRelay<String?>(value: nil)
        private let addressSubject = BehaviorRelay<String?>(value: nil)
        private let conditionAcceptedSubject = BehaviorRelay<Bool>(value: false)
        private let minimumTransactionAmountSubject: LoadableRelay<Double>
        private var processingTxs = [String]()

        // MARK: - Initializers

        init(
            rpcClient: RenVMRpcClientType,
            solanaClient: RenVMSolanaAPIClientType,
            account: SolanaSDK.Account,
            sessionStorage: RenVMLockAndMintSessionStorageType
        ) {
            self.rpcClient = rpcClient
            self.solanaClient = solanaClient
            self.account = account
            self.sessionStorage = sessionStorage
            minimumTransactionAmountSubject = .init(
                request: rpcClient.getTransactionFee(mintTokenSymbol: mintTokenSymbol)
                    .map { $0.convertToBalance(decimals: 8) }
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
                .flatMap { [weak self] solanaChain -> Single<RenVM.LockAndMint.GatewayAddressResponse> in
                    guard let self = self else { throw RenVM.Error.unknown }

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
                .subscribe(onSuccess: { [weak self] response in
                    self?.isLoadingSubject.accept(false)
                    self?.addressSubject.accept(Base58.encode(response.gatewayAddress.bytes))
                    self?.mintStoredTxs(response: response)
                    self?.observeTxStreamAndMint(response: response)
                }, onFailure: { [weak self] error in
                    self?.isLoadingSubject.accept(false)
                    self?.errorSubject.accept(error.readableDescription)
                })
        }

        func expireCurrentSession() {
            sessionStorage.expireCurrentSession()
            reload()
        }

        private func mintStoredTxs(response: RenVM.LockAndMint.GatewayAddressResponse) {
            // get all confirmed and submited txs in storage
            let txs = sessionStorage.getAllProcessingTx()
                .filter { $0.mintedAt == nil && ($0.confirmedAt != nil || $0.submittedAt != nil) }

            // process txs
            for tx in txs {
                processConfirmedAndSubmitedTransaction(tx, response: response)
            }
        }

        private func observeTxStreamAndMint(response: RenVM.LockAndMint.GatewayAddressResponse) {
            // cancel previous observing
            observingTxStreamDisposable?.dispose()

            // refreshing
            observingTxStreamDisposable = Timer.observable(
                seconds: refreshRate,
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

            guard let address = addressSubject.value else { return }

            var url = "https://blockstream.info"
            if rpcClient.network.isTestnet {
                url += "/testnet"
            }
            url += "/api/address/\(address)/utxo"
            let request = try URLRequest(url: url, method: .get)

            RxAlamofire.request(request)
                .responseData()
                .take(1).asSingle()
                .map { try JSONDecoder().decode(TxDetails.self, from: $1) }

                // merge result to storage
                .subscribe(onSuccess: { [weak self] txs in
                    guard let self = self else { return }

                    // filter out processing txs
                    let txs = txs.filter { !self.processingTxs.contains($0.txid) }

                    // log
                    if !txs.isEmpty {
                        Logger.log(message: "renBTC event new transactions: \(txs)", event: .info)
                    }

                    // save processing txs to storage and process confirmed transactions
                    for tx in txs {
                        var date = Date()
                        if let blocktime = tx.status.blockTime {
                            date = Date(timeIntervalSince1970: TimeInterval(blocktime))
                        }

                        if tx.status.confirmed {
                            self.sessionStorage.processingTx(tx: tx, didConfirmAt: date)
                        } else {
                            self.sessionStorage.processingTx(tx: tx, didReceiveAt: date)
                        }

                        self.mintStoredTxs(response: response)
                    }
                })
                .disposed(by: disposeBag)
        }

        private func processConfirmedAndSubmitedTransaction(
            _ tx: ProcessingTx,
            response: RenVM.LockAndMint.GatewayAddressResponse
        ) {
            // Mark as processing
            guard !processingTxs.contains(tx.tx.txid) else { return }
            processingTxs.append(tx.tx.txid)

            // request
            return prepareRequest(response: response, tx: tx)
                .flatMap { [weak self] response -> Single<(amountOut: String?, signature: String)> in
                    guard let self = self else { throw RenVM.Error.unknown }
                    Logger.log(message: "renBTC event mint response: \(response)", event: .info)
                    return self.solanaClient.waitForConfirmation(signature: response.signature)
                        .andThen(.just(response))
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] response in
                    let amount = UInt64(response.amountOut ?? "")
                    let value = (amount ?? tx.tx.value).convertToBalance(decimals: 8)
                        .toString(maximumFractionDigits: 8)
                    self?.notificationsService.showInAppNotification(.message(L10n.receivedRenBTC(value)))

                    // remove minted after 1 minute
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(60)) { [weak self] in
                        self?.sessionStorage.removeMintedTx(txid: tx.tx.txid)
                    }
                }, onFailure: { [weak self] error in
                    // other error
                    Logger.log(
                        message: "renBTC event mint error: \(error), tx: \(String(describing: self?.sessionStorage.getProcessingTx(txid: tx.tx.txid)))",
                        event: .error
                    )
                })
                .disposed(by: disposeBag)
        }

        private func prepareRequest(response: GatewayAddressResponse,
                                    tx: ProcessingTx) -> Single<(amountOut: String?, signature: String)>
        {
            guard let lockAndMint = lockAndMint else {
                return .error(RenVM.Error.unknown)
            }

            // get state
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

            // submitted
            if tx.submittedAt != nil {
                submitMintRequest = .empty()
            }

            // not yet submitted
            else {
                submitMintRequest = submitTransaction(lockAndMint: lockAndMint, state: state, tx: tx)
            }

            // send request
            return submitMintRequest
                .andThen(mint(lockAndMint: lockAndMint, state: state, tx: tx))
                .catch { [weak self] error in
                    guard let self = self else { throw RenVM.Error.unknown }
                    if let error = error as? RenVM.Error,
                       error == .paramsMissing
                    {
                        return Single<Void>.just(())
                            .delay(.seconds(self.mintingRate), scheduler: self.scheduler)
                            .flatMap { [weak self] in
                                guard let self = self else { throw RenVM.Error.unknown }
                                return self.prepareRequest(response: response, tx: tx)
                            }
                    }
                    self.processingTxs.removeAll(where: { $0 == tx.tx.txid })
                    throw error
                }
        }

        private func submitTransaction(
            lockAndMint: RenVM.LockAndMint,
            state: RenVM.State,
            tx: ProcessingTx
        ) -> Completable {
            lockAndMint.submitMintTransaction(state: state)
                .asCompletable()
                .do(onCompleted: { [weak self] in
                    self?.sessionStorage.processingTx(tx: tx.tx, didSubmitAt: Date())
                })
                .catch { _ in
                    .empty() // try to mint no matter what
                }
        }

        private func mint(
            lockAndMint: RenVM.LockAndMint,
            state: RenVM.State,
            tx: ProcessingTx
        ) -> Single<(amountOut: String?, signature: String)> {
            lockAndMint.mint(state: state, signer: account.secretKey)
                .do(onSuccess: { [weak self] _ in
                    self?.sessionStorage.processingTx(tx: tx.tx, didMintAt: Date())
                }, onError: { [weak self] error in
                    if error.isAlreadyInUseSolanaError {
                        Logger.log(message: "txDetail is already minted \(tx)", event: .error)
                        self?.sessionStorage.processingTx(tx: tx.tx, didMintAt: Date())
                    }
                })
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

    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {
        sessionStorage.processingTxsDriver
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

    struct TxDetail: Codable, Hashable {
        let txid: String
        let vout: UInt64
        let status: Status
        let value: UInt64

        struct Status: Codable, Hashable {
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
