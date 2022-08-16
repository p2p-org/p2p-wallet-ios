//
//  EnterSeedInfo.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 18.11.2021.
//

import Combine
import Foundation

protocol EnterSeedInfoViewModelType {
    var navigatableScenePublisher: AnyPublisher<EnterSeedInfo.NavigatableScene?, Never> { get }
    func done()
}

extension EnterSeedInfo {
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        // MARK: - Properties

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
    }
}

extension EnterSeedInfo.ViewModel: EnterSeedInfoViewModelType {
    var navigatableScenePublisher: AnyPublisher<EnterSeedInfo.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func done() {
        navigatableScene = .done
    }
}
