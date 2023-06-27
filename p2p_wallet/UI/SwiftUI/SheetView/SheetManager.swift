//
//  SheetManager.swift
//  p2p_wallet
//
//  Created by Ivan on 01.10.2022.
//

import Foundation

final class SheetManager: ObservableObject {
    @Published private(set) var action: Action = .notAvailable

    static var shared = SheetManager()

    private init() {}

    func present() {
        guard !action.presented else { return }
        action = .present
    }

    func dismiss() {
        action = .dismiss
    }
}

// MARK: - Action

extension SheetManager {
    enum Action {
        case notAvailable
        case present
        case dismiss

        var presented: Bool { self == .present }
    }
}
