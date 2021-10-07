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
    
    var initializingStateDriver: Driver<LoadableState> {get}
    var isNameValidLoadableDriver: Driver<Loadable<Bool>> {get}
    var isPostingDriver: Driver<Bool> {get}
    
    func reload()
    func userDidEnter(name: String?)
    
    func reserveName(geetest_seccode: String, geetest_challenge: String, geetest_validate: String)
    
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
        private let initializingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        private let isNameValidLoadableSubject = LoadableRelay<Bool>(request: .just(false))
        private let isPostingSubject = BehaviorRelay<Bool>(value: false)
        
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
    var initializingStateDriver: Driver<LoadableState> {
        initializingStateSubject.asDriver()
    }
    
    var isNameValidLoadableDriver: Driver<Loadable<Bool>> {
        isNameValidLoadableSubject.asDriver()
    }
    
    var isPostingDriver: Driver<Bool> {
        isPostingSubject.asDriver()
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
    
    func reserveName(geetest_seccode: String, geetest_challenge: String, geetest_validate: String) {
        guard let name = currentName else {return}
        isPostingSubject.accept(true)
        nameService.post(
            name: name,
            params: .init(
                owner: owner,
                credentials: .init(
                    geetest_validate: geetest_validate,
                    geetest_seccode: geetest_seccode,
                    geetest_challenge: geetest_challenge
                )
            )
        )
            .subscribe(onSuccess: {[weak self] _ in
                self?.isPostingSubject.accept(false)
                self?.nameDidReserve(name)
            }, onFailure: {error in
                self.isPostingSubject.accept(false)
                UIApplication.shared.showToast(message: "❌ \(error.readableDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    func nameDidReserve(_ name: String) {
        handler.handleName(name)
    }
    
    func skip() {
        handler.handleName(nil)
    }
}
