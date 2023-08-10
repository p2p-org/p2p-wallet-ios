import SwiftUI

struct RefreshAction {
    let action: () async -> Void
}

struct RefreshActionKey: EnvironmentKey {
    static let defaultValue: RefreshAction? = nil
}

extension EnvironmentValues {
    var refresh: RefreshAction? {
        get { self[RefreshActionKey.self] }
        set { self[RefreshActionKey.self] = newValue }
    }
}

struct RefreshableModifier: ViewModifier {
    let action: () async -> Void

    func body(content: Content) -> some View {
        content
            .environment(\.refresh, RefreshAction(action: action))
            .onRefresh { refreshControl in
                Task {
                    await action()
                    refreshControl.endRefreshing()
                }
            }
    }
}

public extension View {
    @ViewBuilder func customRefreshable(action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 16, *) {
            refreshable(action: action)
        } else {
            modifier(RefreshableModifier(action: action))
        }
    }
}
