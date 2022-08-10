//
//  BuyRoot.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.12.21.
//

import Combine
import Foundation
import Resolver

protocol BuyViewModelType {
    var walletsRepository: WalletsRepository { get }
    var navigationPublisher: AnyPublisher<BuyRoot.NavigatableScene, Never> { get }

    func navigate(to scene: BuyRoot.NavigatableScene)
}

extension BuyRoot {
    @MainActor
    class ViewModel: NSObject, ObservableObject {
        // MARK: - Dependencies

        @Injected var walletsRepository: WalletsRepository

        deinit {
            print("\(String(describing: self)) deinited")
        }

        // MARK: - Subject

        private let navigationSubject = PassthroughSubject<NavigatableScene, Never>()
    }
}

extension BuyRoot.ViewModel: BuyViewModelType {
    var navigationPublisher: AnyPublisher<BuyRoot.NavigatableScene, Never> {
        navigationSubject.replaceError(with: .none).eraseToAnyPublisher()
    }

    // MARK: - Actions

    func navigate(to scene: BuyRoot.NavigatableScene) {
        navigationSubject.send(scene)
    }
}
