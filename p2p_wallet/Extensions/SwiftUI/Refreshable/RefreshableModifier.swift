//
//  RefreshableModifier.swift
//  SwiftUI_Pull_to_Refresh
//
//  Created by Geri Borbás on 15/03/2022.
//

import SwiftUI

struct RefreshAction {
    let action: () async -> Void

    func callAsFunction() async {
        await action()
    }
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
        // TODO: - Uncomment later when migrating to xcode 14, refreshable not work for xcode 13
//        if #available(iOS 15.0, *) {
//            refreshable(action: action)
//        } else {
            modifier(RefreshableModifier(action: action))
//        }
    }
}
