//
//  ReserveName.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReserveNameViewModelType {
    var currentName: String? {get}
    
    var navigationDriver: Driver<ReserveName.NavigatableScene?> {get}
    var initializingStateDriver: Driver<LoadableState> {get}
    var isNameValidLoadableDriver: Driver<Loadable<Bool>> {get}
    
    func reload()
    func userDidEnter(name: String?)
    
    func showCaptcha()
    
    func nameDidReserve(_ name: String)
}

extension ReserveName {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var nameService: NameServiceType
        private let owner: String
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        var currentName: String?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let initializingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        private let isNameValidLoadableSubject = LoadableRelay<Bool>(request: .just(false))
        
        // MARK: - Initializer
        init(owner: String) {
            self.owner = owner
            
            reload()
        }
        
        private func checkIfOwnerHasAlreadyRegistered() {
            initializingStateSubject.accept(.loading)
            nameService.getName(owner)
                .subscribe(onSuccess: {[weak self] names in
                    self?.initializingStateSubject.accept(.loaded)
                    if !names.isEmpty {
                        self?.nameDidReserve(names.first!.name)
                    }
                }, onFailure: {[weak self] error in
                    self?.initializingStateSubject.accept(.error(error.readableDescription))
                })
                .disposed(by: disposeBag)
        }
    }
}

extension ReserveName.ViewModel: ReserveNameViewModelType {
    var navigationDriver: Driver<ReserveName.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var initializingStateDriver: Driver<LoadableState> {
        initializingStateSubject.asDriver()
    }
    
    var isNameValidLoadableDriver: Driver<Loadable<Bool>> {
        isNameValidLoadableSubject.asDriver()
    }
    
    // MARK: - Actions
    func reload() {
        checkIfOwnerHasAlreadyRegistered()
    }
    
    func userDidEnter(name: String?) {
        currentName = name
        // check for availability
        if let name = name {
            isNameValidLoadableSubject.request = nameService.isNameAvailable(name, owner: owner)
        } else {
            isNameValidLoadableSubject.request = .just(false)
        }
        isNameValidLoadableSubject.reload()
    }
    
    func showCaptcha() {
        navigationSubject.accept(.showCaptcha)
    }
    
    func nameDidReserve(_ name: String) {
        
    }
}
