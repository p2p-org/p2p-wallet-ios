//
//  LoadableRelay.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/09/2021.
//

import Foundation
import RxCocoa
import RxSwift

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

    func setUp(
        _ loadableState: LoadableState,
        overridingErrorAction: @escaping (() -> Void)
    ) {
        switch loadableState {
        case .notRequested, .loading:
            showIndetermineHud()
        case .loaded:
            hideHud()
        case .error:
            hideHud()
            overridingErrorAction()
        }
    }
}

extension Reactive where Base: UIView {
    func loadableState(reloadAction: @escaping (() -> Void)) -> Binder<LoadableState> {
        Binder(base) { view, loadableState in
            view.setUp(loadableState, reloadAction: reloadAction)
        }
    }
}

extension Collection where Element == LoadableState {
    var combined: Element {
        // if there is some error, return error
        if contains(where: { $0.isError }) { return .error(nil) }
        // if all loaded, return loaded
        if allSatisfy({ $0 == .loaded }) { return .loaded }
        // if there is 1 loading, return loading
        if contains(where: { $0 == .loading }) { return .loading }
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
    public var state: LoadableState { stateRelay.value }

    private var disposable: Disposable?

    public var stateObservable: Observable<LoadableState> { stateRelay.asObservable() }
    public var valueObservable: Observable<T?> {
        stateRelay
            .map { [weak self] _ in self?.value }
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
            .subscribe(onSuccess: { [weak self] data in
                guard let self = self else { return }
                self.value = self.map(oldData: self.value, newData: data)
                self.stateRelay.accept(.loaded)
            }, onFailure: { [weak self] error in
                self?.stateRelay.accept(.error(error.readableDescription))
            })
    }

    /// Mapping
    public func map(oldData _: T?, newData: T) -> T {
        newData
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

public extension LoadableRelay {
    /// Convert to driver to drive UI
    func asDriver() -> Driver<Loadable<T>> {
        stateObservable.asDriver(onErrorJustReturn: .notRequested)
            .map { [weak self] in (value: self?.value, state: $0, reloadAction: { [weak self] in self?.reload() }) }
    }
}

public extension Reactive where Base: UILabel {
    /// Bindable sink for `loadbleText` property.
    func loadableText<T>(
        onLoaded: @escaping ((T?) -> String?)
    ) -> Binder<Loadable<T>> {
        Binder(base) { label, loadableValue in
            label.set(loadableValue, onLoaded: onLoaded)
        }
    }
}

public extension UILabel {
    func set<T>(_ loadableValue: Loadable<T>, onLoaded: @escaping ((T?) -> String?)) {
        isUserInteractionEnabled = false
        switch loadableValue.state {
        case .notRequested:
            text = L10n.loading + "..."
        case .loading:
            text = L10n.loading + "..."
        case .loaded:
            text = onLoaded(loadableValue.value)
        case .error:
            isUserInteractionEnabled = true
            text = L10n.error.uppercaseFirst + ". " + L10n.tapToTryAgain

            let gesture = LoadableTapGesture(target: self, action: #selector(loadableTextDidTap(gesture:)))
            gesture.reloadAction = loadableValue.reloadAction
            addGestureRecognizer(gesture)
        }
    }

    @objc func loadableTextDidTap(gesture: UIGestureRecognizer) {
        guard let gesture = gesture as? LoadableTapGesture else { return }
        gesture.reloadAction?()
    }
}

class LoadableTapGesture: UITapGestureRecognizer {
    var reloadAction: (() -> Void)?
}
