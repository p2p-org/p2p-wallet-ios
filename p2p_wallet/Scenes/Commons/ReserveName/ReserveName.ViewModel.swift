//
//  ReserveName.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol ReserveNameHandler {
    func handleName(_ name: String?)
}

protocol ReserveNameViewModelType {
    var currentName: String? {get}
    
    var navigationDriver: Driver<ReserveName.NavigatableScene?> {get}
    var initializingStateDriver: Driver<LoadableState> {get}
    var isNameValidLoadableDriver: Driver<Loadable<Bool>> {get}
    
    func reload()
    func userDidEnter(name: String?)
    
    func process()
    
    func nameDidReserve(_ name: String)
    func skip()
}

extension ReserveName {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var nameService: NameServiceType
        private let owner: String
        private let handler: ReserveNameHandler
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        var currentName: String?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let initializingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        private let isNameValidLoadableSubject = LoadableRelay<Bool>(request: .just(false))
        
        // MARK: - Initializer
        init(owner: String, handler: ReserveNameHandler) {
            self.owner = owner
            self.handler = handler
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
        if let name = name, !name.isEmpty {
            isNameValidLoadableSubject.request = nameService.isNameAvailable(name)
            isNameValidLoadableSubject.reload()
        } else {
            isNameValidLoadableSubject.accept(false, state: .loaded)
        }
        
    }
    
    func process() {
        navigationSubject.accept(.showCaptcha)
    }
    
    func nameDidReserve(_ name: String) {
        handler.handleName(name)
    }
    
    func skip() {
        handler.handleName(nil)
    }
}
