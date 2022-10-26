//
//  LoadableRelay.swift
//  p2p_wallet
//
//  Created by Chung Tran on 04/09/2021.
//

import Combine
import Foundation

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

            showErrorView(
                title: L10n.error,
                description: L10n.somethingWentWrong + ". " + L10n.pleaseTryAgainLater.uppercaseFirst,
                retryAction: {
                    reloadAction()
                }
            )
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

extension Collection where Element == LoadableState {
    var combined: Element {
        // if there is some error, return error
        if contains(where: \.isError) { return .error(nil) }
        // if all loaded, return loaded
        if allSatisfy({ $0 == .loaded }) { return .loaded }
        // if there is 1 loading, return loading
        if contains(where: { $0 == .loading }) { return .loading }
        // default
        return .notRequested
    }
}

@MainActor
public class LoadableRelay<T>: ObservableObject {
    // MARK: - Subject

    @Published public private(set) var state = LoadableState.notRequested
    @Published public private(set) var value: T?

    // MARK: - Properties

    public var request: (() async throws -> T)?

    private var task: Task<Void, Never>?

    // MARK: - Initializer

    public init(request: (() async throws -> T)? = nil) {
        self.request = request
    }

    // MARK: - Actions

    /// Flush result
    public func flush() {
        cancelRequest()
        value = nil
        state = .notRequested
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
        state = .loading

        // Load request
        task = Task {
            do {
                try Task.checkCancellation()
                guard let data = try await request?() else {
                    await MainActor.run { [weak self] in
                        self?.state = .loaded
                    }
                    return
                }
                try Task.checkCancellation()
                await MainActor.run { [weak self] in
                    guard let self = self else {return}
                    self.value = self.map(oldData: self.value, newData: data)
                    self.state = .loaded
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .error(error.readableDescription)
                }
            }
        }
    }

    /// Mapping
    public func map(oldData _: T?, newData: T) -> T {
        newData
    }

    /// Cancel current request
    public func cancelRequest() {
        task?.cancel()
    }

    /// Override value by a given value and set state to loaded
    /// - Parameter value: value for overriding
    public func send(_ value: T?, state: LoadableState) {
        cancelRequest()
        self.value = value
        self.state = state
    }
}

public typealias Loadable<T> = (value: T?, state: LoadableState, reloadAction: (() -> Void)?)

public extension LoadableRelay {
    /// Convert to publisher
    func eraseToAnyPublisher() -> AnyPublisher<Loadable<T>, Never> {
        $state
            .map { [weak self] in (value: self?.value, state: $0, reloadAction: { [weak self] in self?.reload() }) }
            .eraseToAnyPublisher()
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
