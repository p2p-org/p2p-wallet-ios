//
//  Home.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift

protocol HomeViewModelType {
    var navigationDriver: Driver<Home.NavigatableScene?> { get }
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> { get }

    var nameDidReserveSignal: Signal<Void> { get }
    var walletsRepository: WalletsRepository { get }
    var bannerViewModel: Home.BannerViewModel { get }

    func navigate(to scene: Home.NavigatableScene?)
}

extension Home {
    class ViewModel {
        // MARK: - Dependencies

        @Injected var walletsRepository: WalletsRepository
        @Injected var pricesService: PricesServiceType
        let bannerViewModel = BannerViewModel(service: Resolver.resolve())

        // MARK: - Subjects

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let nameDidReserveSubject = PublishRelay<Void>()

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension Home.ViewModel: HomeViewModelType {
    var navigationDriver: Driver<Home.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> {
        pricesService.currentPricesDriver
    }

    var nameDidReserveSignal: Signal<Void> {
        nameDidReserveSubject.asSignal()
    }

    // MARK: - Actions

    func navigate(to scene: Home.NavigatableScene?) {
        navigationSubject.accept(scene)
    }
}
