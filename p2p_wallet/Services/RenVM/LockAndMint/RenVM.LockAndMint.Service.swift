//
//  LockAndMint.Service.swift
//  p2p_wallet
//
//  Created by Chung Tran on 17/09/2021.
//

import Foundation
import RenVMSwift
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol RenVMLockAndMintServiceType {
    var isLoadingDriver: Driver<Bool> { get }
    var errorDriver: Driver<String?> { get }
    var addressDriver: Driver<String?> { get }
    var minimumTransactionAmountDriver: Driver<Loadable<Double>> { get }
    var processingTxsDriver: Driver<[LockAndMint.ProcessingTx]> { get }

    func reload()
    func reloadMinimumTransactionAmount()
    func loadSession()
    func expireCurrentSession()
    func getSessionEndDate() -> Date?
    func getCurrentAddress() -> String?
}

extension LockAndMint {
    class Service {
        // MARK: - Constants

        private let refreshRate = 3 // in seconds, refreshing frequency
        private let mintingRate = 60 // in seconds, time between 2 minting attempts
        private let mintTokenSymbol = "BTC"
        private let version = "1"
        private let disposeBag = DisposeBag()

        // MARK: - Dependencies

        private let rpcClient: RenVMRpcClientType
        private let solanaClient: SolanaAPIClient
        private let account: Account
        private let sessionStorage: RenVMLockAndMintSessionStorageType
        @Injected private var notificationsService: NotificationService

        // MARK: - Properties

        private var loadingDisposable: Disposable?
        private var lockAndMint: LockAndMint?
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
        private let minimumTransactionAmountSubject: LoadableRelay<Double>
        private var processingTxs = [String]()

        // MARK: - Initializers

        init(
            rpcClient: RenVMRpcClientType,
            solanaClient: SolanaAPIClient,
            account: Account,
            sessionStorage: RenVMLockAndMintSessionStorageType
        ) {
            self.rpcClient = rpcClient
            self.solanaClient = solanaClient
            self.account = account
            self.sessionStorage = sessionStorage
            minimumTransactionAmountSubject = .init(
                request: Single.async { () async throws -> Double in
                    // TODO: fix
                    // let value = try await rpcClient.getTransactionFee(mintTokenSymbol: self?.mintTokenSymbol)
                    // return value.convertToBalance(decimals: 8)
                    0.0
                }
            )

            reload()
            reloadMinimumTransactionAmount()
        }

        // MARK: - Sessions

        func reload() {
            // clear old values
            isLoadingSubject.accept(false)
            errorSubject.accept(nil)
            addressSubject.accept(nil)
            loadingDisposable?.dispose()
            observingTxStreamDisposable?.dispose()

            // if session exists, condition accepted, load session
            if let session = sessionStorage.loadSession() {
                if Date() >= session.endAt {
                    expireCurrentSession()
                } else {
                    loadSession()
                }
            }
        }

        func reloadMinimumTransactionAmount() {
            minimumTransactionAmountSubject.reload()
        }

        func loadSession() {
            loadSession(savedSession: sessionStorage.loadSession())
        }

        private func loadSession(savedSession _: RenVMSwift.Session?) {
            fatalError("Method has not been implemented")

            // // set loading
            // isLoadingSubject.accept(true)
            //
            // loadingDisposable?.dispose()
            //
            // // request
            // loadingDisposable = RenVM.SolanaChain.load(
            //     client: rpcClient,
            //     solanaClient: solanaClient
            // )
            //     .observe(on: MainScheduler.instance)
            //     .flatMap { [weak self] solanaChain -> Single<LockAndMint.GatewayAddressResponse> in
            //         guard let self = self else { throw RenVMError.unknown }
            //
            //         // create lock and mint
            //         self.lockAndMint = try .init(
            //             rpcClient: self.rpcClient,
            //             chain: solanaChain,
            //             mintTokenSymbol: self.mintTokenSymbol,
            //             version: self.version,
            //             destinationAddress: self.account.publicKey.data,
            //             session: savedSession
            //         )
            //
            //         // save session
            //         if savedSession == nil {
            //             self.sessionStorage.saveSession(self.lockAndMint!.session)
            //         }
            //
            //         // generate address
            //         return self.lockAndMint!.generateGatewayAddress()
            //     }
            //     .observe(on: MainScheduler.instance)
            //     .subscribe(onSuccess: { [weak self] response in
            //         self?.isLoadingSubject.accept(false)
            //         self?.addressSubject.accept(Base58.encode(response.gatewayAddress.bytes))
            //         self?.mintStoredTxs(response: response)
            //         self?.observeTxStreamAndMint(response: response)
            //     }, onFailure: { [weak self] error in
            //         self?.isLoadingSubject.accept(false)
            //         self?.errorSubject.accept(error.readableDescription)
            //     })
        }

        func expireCurrentSession() {
            sessionStorage.expireCurrentSession()
            reload()
        }

        private func mintStoredTxs(response: LockAndMint.GatewayAddressResponse) {
            // get all confirmed and submited txs in storage
            let txs = sessionStorage.getAllProcessingTx()
                .filter { $0.mintedAt == nil && ($0.confirmedAt != nil || $0.submittedAt != nil) }

            // process txs
            for tx in txs {
                processConfirmedAndSubmitedTransaction(tx, response: response)
            }
        }

        private func observeTxStreamAndMint(response: LockAndMint.GatewayAddressResponse) {
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

        private func observeTxStatusAndMint(response: LockAndMint.GatewayAddressResponse) throws {
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
            let request = URLRequest(url: .init(string: url)!)

            return Single<[IncomingTransaction]>.async {
                let (data, _) = try await URLSession.shared.data(from: request)
                return try JSONDecoder().decode([IncomingTransaction].self, from: data)
            }
            // merge result to storage
                .subscribe(onSuccess: { [weak self] txs in
                    guard let self = self else { return }

                    // filter out processing txs
                    let txs = txs.filter { !self.processingTxs.contains($0.txid) }

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
            _: ProcessingTx,
            response _: LockAndMint.GatewayAddressResponse
        ) {
            fatalError("Method has not been implemented")

            // // Mark as processing
            // guard !processingTxs.contains(tx.tx.txid) else { return }
            // processingTxs.append(tx.tx.txid)
            //
            // // request
            // return prepareRequest(response: response, tx: tx)
            //     .flatMap { [weak self] response -> Single<(amountOut: String?, signature: String)> in
            //         guard let self = self else { throw RenVMError.unknown }
            //         Logger.log(message: "renBTC event mint response: \(response)", event: .info)
            //         return self.solanaClient.waitForConfirmation(signature: response.signature)
            //             .andThen(.just(response))
            //     }
            //     .observe(on: MainScheduler.instance)
            //     .subscribe(onSuccess: { [weak self] response in
            //         let amount = UInt64(response.amountOut ?? "")
            //         let value = (amount ?? tx.tx.value).convertToBalance(decimals: 8)
            //             .toString(maximumFractionDigits: 8)
            //         self?.notificationsService.showInAppNotification(.message(L10n.receivedRenBTC(value)))
            //
            //         // remove minted after 1 minute
            //         DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(60)) { [weak self] in
            //             self?.sessionStorage.removeMintedTx(txid: tx.tx.txid)
            //         }
            //     })
            //     .disposed(by: disposeBag)
        }

        private func prepareRequest(response: GatewayAddressResponse,
                                    tx: ProcessingTx) -> Single<(amountOut: String?, signature: String)>
        {
            guard let lockAndMint = lockAndMint else {
                return .error(RenVMError.unknown)
            }

            // get state
            let state: RenVMSwift.State

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
                    guard let self = self else { throw RenVMError.unknown }
                    if let error = error as? RenVMError,
                       error == .paramsMissing
                    {
                        return Single<Void>.just(())
                            .delay(.seconds(self.mintingRate), scheduler: self.scheduler)
                            .flatMap { [weak self] in
                                guard let self = self else { throw RenVMError.unknown }
                                return self.prepareRequest(response: response, tx: tx)
                            }
                    }
                    self.processingTxs.removeAll(where: { $0 == tx.tx.txid })
                    throw error
                }
        }

        private func submitTransaction(
            lockAndMint _: LockAndMint,
            state _: RenVMSwift.State,
            tx _: ProcessingTx
        ) -> Completable {
            fatalError("Method has not been implemented")

            // lockAndMint.submitMintTransaction(state: state)
            //     .asCompletable()
            //     .do(onCompleted: { [weak self] in
            //         self?.sessionStorage.processingTx(tx: tx.tx, didSubmitAt: Date())
            //     })
            //     .catch { _ in
            //         .empty() // try to mint no matter what
            //     }
        }

        private func mint(
            lockAndMint _: LockAndMint,
            state _: RenVMSwift.State,
            tx _: ProcessingTx
        ) -> Single<(amountOut: String?, signature: String)> {
            fatalError("Method has not been implemented")

            // lockAndMint.mint(state: state, signer: account.secretKey)
            //     .do(onSuccess: { [weak self] _ in
            //         self?.sessionStorage.processingTx(tx: tx.tx, didMintAt: Date())
            //     }, onError: { [weak self] error in
            //         if error.isAlreadyInUseSolanaError {
            //             Logger.log(message: "txDetail is already minted \(tx)", event: .error)
            //             self?.sessionStorage.processingTx(tx: tx.tx, didMintAt: Date())
            //         }
            //     })
        }
    }
}

extension LockAndMint.Service: RenVMLockAndMintServiceType {
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorSubject.asDriver()
    }

    var addressDriver: Driver<String?> {
        addressSubject.asDriver()
    }

    var minimumTransactionAmountDriver: Driver<Loadable<Double>> {
        minimumTransactionAmountSubject.asDriver()
    }

    var processingTxsDriver: Driver<[LockAndMint.ProcessingTx]> {
        sessionStorage.processingTxsDriver
    }

    func getSessionEndDate() -> Date? {
        sessionStorage.loadSession()?.endAt
    }

    func getCurrentAddress() -> String? {
        addressSubject.value
    }
}
