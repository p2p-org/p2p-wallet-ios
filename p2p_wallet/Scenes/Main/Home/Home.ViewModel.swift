//
//  Home.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import Combine
import Foundation
import Resolver
import SolanaPricesAPIs

protocol HomeViewModelType: ReserveNameHandler {
    var navigatableScenePublisher: AnyPublisher<Home.NavigatableScene?, Never> { get }
    var pricesLoadingStatePublisher: AnyPublisher<LoadableState, Never> { get }
    var scrollToTopPublisher: AnyPublisher<Void, Never> { get }

    var walletsRepository: WalletsRepository { get }
    var bannerViewModel: Home.BannerViewModel { get }

    func getOwner() -> String?

    func navigate(to scene: Home.NavigatableScene?)
    func scrollToTop()
}

extension Home {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected var walletsRepository: WalletsRepository
        @Injected var pricesService: PricesServiceType
        @Injected var storage: AccountStorageType & NameStorageType
        let bannerViewModel = BannerViewModel(service: Resolver.resolve())

        // MARK: - Subjects

        @Published private var navigationSubject: NavigatableScene?
        private let scrollToTopSubject = PassthroughSubject<Void, Never>()

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension Home.ViewModel: HomeViewModelType {
    var scrollToTopPublisher: AnyPublisher<Void, Never> {
        scrollToTopSubject.eraseToAnyPublisher()
    }

    func handleName(_ name: String?) {
        guard let name = name else { return }
        storage.save(name: name)
    }

    func getOwner() -> String? {
        walletsRepository.nativeWallet?.pubkey
    }

    var navigatableScenePublisher: AnyPublisher<Home.NavigatableScene?, Never> {
        $navigationSubject.eraseToAnyPublisher()
    }

    var pricesLoadingStatePublisher: AnyPublisher<LoadableState, Never> {
        pricesService.statePublisher
    }

    // MARK: - Actions

    func navigate(to scene: Home.NavigatableScene?) {
        navigationSubject = scene
    }

    func scrollToTop() {
        scrollToTopSubject.send()
    }
}
