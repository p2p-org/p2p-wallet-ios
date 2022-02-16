//
//  RenBTCReceivingStatuses.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import RxSwift
import RxCocoa
import BECollectionView
import RenVMSwift

protocol RenBTCReceivingStatusesViewModelType: BEListViewModelType {
    var navigationDriver: Driver<RenBTCReceivingStatuses.NavigatableScene?> {get}
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {get}
    func showDetail(txid: String)
}

extension RenBTCReceivingStatuses {
    class ViewModel {
        // MARK: - Dependencies
        let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType
        
        // MARK: - Properties
        let disposeBag = DisposeBag()
        var data = [RenVM.LockAndMint.ProcessingTx]()
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        
        // MARK: - Initializer
        init(receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType) {
            self.receiveBitcoinViewModel = receiveBitcoinViewModel
            bind()
        }
        
        func bind() {
            receiveBitcoinViewModel.processingTxsDriver
                .drive(onNext: { [weak self] in
                    let new = Array($0.reversed())
                    self?.data = new
                })
                .disposed(by: disposeBag)
        }
    }
}

extension RenBTCReceivingStatuses.ViewModel: BEListViewModelType {
    var dataDidChange: Observable<Void> {
        receiveBitcoinViewModel.processingTxsDriver.map {_ in ()}.asObservable()
    }
    
    var currentState: BEFetcherState {
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
    
    func setState(_ state: BEFetcherState, withData data: [AnyHashable]?) {
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
    var navigationDriver: Driver<RenBTCReceivingStatuses.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {
        receiveBitcoinViewModel.processingTxsDriver
    }
    
    // MARK: - Actions
    func showDetail(txid: String) {
        navigationSubject.accept(.detail(txid: txid))
    }
}
