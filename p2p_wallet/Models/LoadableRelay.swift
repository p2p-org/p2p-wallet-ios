//
//  LoadableRelay.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/09/2021.
//

import Foundation
import RxSwift
import RxCocoa

public enum LoadableState: Equatable {
    case notRequested
    case loading
    case loaded
    case error(String?)
    
    var isError: Bool {
        switch self {
        case .error: return true
        default: return false
        }
    }
}

extension UIView {
    func setUp(
        _ loadableState: LoadableState,
        reloadAction: @escaping (() -> Void)
    ) {
        switch loadableState {
        case .notRequested:
            hideHud()
        case .loading:
            showIndetermineHud()
        case .loaded:
            hideHud()
        case .error:
            hideHud()
            
            showErrorView(title: L10n.error, description: L10n.somethingWentWrong + ". " + L10n.pleaseTryAgainLater.uppercaseFirst, retryAction: .init(workFactory: { _ in
                reloadAction()
                return .just(())
            }))
        }
    }
}

extension Reactive where Base: UIView {
    func loadableState(reloadAction: @escaping (() -> Void)) -> Binder<LoadableState> {
        Binder(base) {view, loadableState in
            view.setUp(loadableState, reloadAction: reloadAction)
        }
    }
}

class LoadableRelay<T> {
    // MARK: - Subject
    private let stateRelay = BehaviorRelay<LoadableState>(value: .notRequested)
    
    // MARK: - Properties
    var request: Single<T>
    private(set) var value: T?
    var state: LoadableState {stateRelay.value}
    
    private var disposable: Disposable?
    
    var stateObservable: Observable<LoadableState> {stateRelay.asObservable()}
    var valueObservable: Observable<T?> {
        stateRelay
            .map {[weak self] _ in self?.value}
            .asObservable()
    }
    // MARK: - Initializer
    init(request: Single<T>) {
        self.request = request
    }
    
    // MARK: - Actions
    
    /// Flush result
    func flush() {
        cancelRequest()
        value = nil
        stateRelay.accept(.notRequested)
    }
    
    /// Flush result and refresh
    func reload() {
        flush()
        refresh()
    }
    
    /// Reload request
    func refresh() {
        // Cancel previous request
        cancelRequest()
        
        // Mark as loading
        stateRelay.accept(.loading)
        
        // Load request
        disposable = request
            .subscribe(onSuccess: {[weak self] data in
                self?.value = data
                self?.stateRelay.accept(.loaded)
            }, onFailure: {[weak self] error in
                self?.stateRelay.accept(.error(error.readableDescription))
            })
    }
    
    /// Cancel current request
    func cancelRequest() {
        disposable?.dispose()
    }
    
    /// Override value by a given value and set state to loaded
    /// - Parameter value: value for overriding
    func accept(_ value: T?, state: LoadableState) {
        cancelRequest()
        self.value = value
        stateRelay.accept(state)
    }
}

public typealias Loadable<T> = (value: T?, state: LoadableState, reloadAction: (() -> Void)?)

extension LoadableRelay {
    /// Convert to driver to drive UI
    public func asDriver() -> Driver<Loadable<T>> {
        stateObservable.asDriver(onErrorJustReturn: .notRequested)
            .map {[weak self] in (value: self?.value, state: $0, reloadAction: {[weak self] in self?.reload()})}
    }
}
