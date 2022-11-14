//
//  RenBTCReceivingStatuses.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import BECollectionView_Combine
import Foundation
import RenVMSwift
import Combine

extension RenBTCReceivingStatuses {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        let receiveBitcoinViewModel: ReceiveToken.ReceiveBitcoinViewModel

        // MARK: - Properties

        var subscriptions = Set<AnyCancellable>()
        var data = [LockAndMint.ProcessingTx]()

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        var navigationPublisher: AnyPublisher<NavigatableScene?, Never> {
            $navigatableScene.receive(on: RunLoop.main).eraseToAnyPublisher()
        }

        // MARK: - Initializer

        init(receiveBitcoinViewModel: ReceiveToken.ReceiveBitcoinViewModel) {
            self.receiveBitcoinViewModel = receiveBitcoinViewModel
            bind()
        }

        func bind() {
            receiveBitcoinViewModel.processingTransactionsPublisher
                .map {$0.reversed()}
                .assign(to: \.data, on: self)
                .store(in: &subscriptions)
        }
        
        // MARK: - Actions
        func showDetail(txid: String) {
            navigatableScene = .detail(txid: txid)
        }
    }
}

extension RenBTCReceivingStatuses.ViewModel: BECollectionViewModelType {
    var dataDidChange: AnyPublisher<Void, Never> {
        receiveBitcoinViewModel.processingTransactionsPublisher.map {_ in ()}.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    var state: BECollectionView_Core.BEFetcherState {
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
}
