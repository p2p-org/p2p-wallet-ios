//
//  RenBTCReceivingStatuses.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import BECollectionView_Combine
import Combine
import Foundation
import RenVMSwift

protocol RenBTCReceivingStatusesViewModelType: BECollectionViewModelType {
    var navigatableScenePublisher: AnyPublisher<RenBTCReceivingStatuses.NavigatableScene?, Never> { get }
    var processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> { get }
    func showDetail(txid: String)
}

extension RenBTCReceivingStatuses {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType

        // MARK: - Properties

        var subscriptions = [AnyCancellable]()
        var data = [LockAndMint.ProcessingTx]()

        // MARK: - Subject

        @Published private var navigationSubject: NavigatableScene?

        // MARK: - Initializer

        init(receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType) {
            self.receiveBitcoinViewModel = receiveBitcoinViewModel
            bind()
        }

        func bind() {
            receiveBitcoinViewModel.processingTxsPublisher
                .sink { [weak self] in
                    let new = Array($0.reversed())
                    self?.data = new
                }
                .store(in: &subscriptions)
        }
    }
}

extension RenBTCReceivingStatuses.ViewModel: BECollectionViewModelType {
    var dataDidChange: AnyPublisher<Void, Never> {
        receiveBitcoinViewModel.processingTxsPublisher.map { _ in () }
            .eraseToAnyPublisher()
    }

    var state: BEFetcherState {
        .loaded
    }

    var isPaginationEnabled: Bool {
        false
    }

    func reload() {
        // do nothing
    }

    func convertDataToAnyHashable() -> [AnyHashable] {
        data as [AnyHashable]
    }

    func fetchNext() {
        // do nothing
    }

    func setState(_: BEFetcherState, withData _: [AnyHashable]?) {
        // do nothing
    }

    func refreshUI() {
        // do nothing
    }

    func getCurrentPage() -> Int? {
        0
    }
}

extension RenBTCReceivingStatuses.ViewModel: RenBTCReceivingStatusesViewModelType {
    var navigatableScenePublisher: AnyPublisher<RenBTCReceivingStatuses.NavigatableScene?, Never> {
        $navigationSubject.eraseToAnyPublisher()
    }

    var processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> {
        receiveBitcoinViewModel.processingTxsPublisher
    }

    // MARK: - Actions

    func showDetail(txid: String) {
        navigationSubject = .detail(txid: txid)
    }
}
