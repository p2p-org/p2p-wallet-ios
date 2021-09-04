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
}

public class LoadableRelay<T> {
    // MARK: - Subject
    private let stateRelay = BehaviorRelay<LoadableState>(value: .notRequested)
    
    // MARK: - Properties
    public var request: Single<T>
    public private(set) var value: T?
    public var state: LoadableState {stateRelay.value}
    
    private var disposable: Disposable?
    
    public var stateObservable: Observable<LoadableState> {stateRelay.asObservable()}
    public var valueObservable: Observable<T?> {
        stateRelay
            .map {[weak self] _ in self?.value}
            .asObservable()
    }
    // MARK: - Initializer
    public init(request: Single<T>) {
        self.request = request
    }
    
    // MARK: - Actions
    
    /// Flush result
    public func flush() {
        cancelRequest()
        value = nil
        stateRelay.accept(.notRequested)
    }
    
    /// Flush result and refresh
    public func reload() {
        flush()
        refresh()
    }
    
    /// Reload request
    public func refresh() {
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
    public func cancelRequest() {
        disposable?.dispose()
    }
    
    /// Override value by a given value and set state to loaded
    /// - Parameter value: value for overriding
    public func accept(_ value: T?, state: LoadableState) {
        cancelRequest()
        self.value = value
        stateRelay.accept(state)
    }
}
