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
        case .error(_): return true
        default: return false
        }
    }
}

extension Collection where Element == LoadableState {
    var combined: Element {
        // if there is some error, return error
        if contains(where: {$0.isError}) {return .error(nil)}
        // if all loaded, return loaded
        if allSatisfy({$0 == .loaded}) {return .loaded}
        // if there is 1 loading, return loading
        if contains(where: {$0 == .loading}) {return .loading}
        // default
        return .notRequested
    }
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

public typealias Loadable<T> = (value: T?, state: LoadableState, reloadAction: (() -> Void)?)

extension LoadableRelay {
    /// Convert to driver to drive UI
    public func asDriver() -> Driver<Loadable<T>> {
        stateObservable.asDriver(onErrorJustReturn: .notRequested)
            .map {[weak self] in (value: self?.value, state: $0, reloadAction: {[weak self] in self?.reload()})}
    }
}

extension Reactive where Base: UILabel {
    /// Bindable sink for `loadbleText` property.
    public func loadableText<T>(
        onLoaded: @escaping ((T?) -> String?)
    ) -> Binder<Loadable<T>> {
        Binder(self.base) {label, loadableValue in
            label.set(loadableValue, onLoaded: onLoaded)
        }
    }
}

extension UILabel {
    public func set<T>(_ loadableValue: Loadable<T>, onLoaded: @escaping ((T?) -> String?)) {
        isUserInteractionEnabled = false
        switch loadableValue.state {
        case .notRequested:
            attributedText = NSMutableAttributedString()
                .text(L10n.loading + "...")
        case .loading:
            attributedText = NSMutableAttributedString()
                .text(L10n.loading + "...")
        case .loaded:
            attributedText = NSMutableAttributedString()
                .text(onLoaded(loadableValue.value) ?? "")
        case .error(_):
            isUserInteractionEnabled = true
            
            attributedText = NSMutableAttributedString()
                .text(L10n.error.uppercaseFirst + ". " + L10n.tapToTryAgain, size: font.pointSize, weight: font.weight, color: .alert)
            
            let gesture = LoadableTapGesture(target: self, action: #selector(loadableTextDidTap(gesture:)))
            gesture.reloadAction = loadableValue.reloadAction
            addGestureRecognizer(gesture)
        }
    }
    
    @objc public func loadableTextDidTap(gesture: UIGestureRecognizer) {
        guard let gesture = gesture as? LoadableTapGesture else {return}
        gesture.reloadAction?()
    }
}

class LoadableTapGesture: UITapGestureRecognizer {
    var reloadAction: (() -> Void)?
}
