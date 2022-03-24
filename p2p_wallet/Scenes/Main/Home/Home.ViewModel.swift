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

protocol HomeViewModelType: ReserveNameHandler {
    var navigationDriver: Driver<Home.NavigatableScene?> { get }
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> { get }

    var walletsRepository: WalletsRepository { get }
    var bannerViewModel: Home.BannerViewModel { get }

    func getOwner() -> String?

    func navigate(to scene: Home.NavigatableScene?)
    func navigateToScanQrCodeWithSwiper(progress: CGFloat, swiperState: UIGestureRecognizer.State)
}

extension Home {
    class ViewModel {
        // MARK: - Dependencies

        @Injected var storage: AccountStorageType & NameStorageType
        @Injected var notificationsService: NotificationsServiceType
        @Injected var walletsRepository: WalletsRepository
        @Injected var pricesService: PricesServiceType
        let bannerViewModel = BannerViewModel(service: Resolver.resolve())

        // MARK: - Subjects

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension Home.ViewModel: HomeViewModelType {
    func handleName(_ name: String?) {
        guard let name = name else { return }
        storage.save(name: name)
    }

    func getOwner() -> String? {
        walletsRepository.nativeWallet?.pubkey
    }

    var navigationDriver: Driver<Home.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> {
        pricesService.currentPricesDriver
    }

    // MARK: - Actions

    func navigate(to scene: Home.NavigatableScene?) {
        navigationSubject.accept(scene)
    }

    func navigateToScanQrCodeWithSwiper(progress: CGFloat, swiperState: UIGestureRecognizer.State) {
        navigationSubject.accept(.scanQrWithSwiper(progress: progress, state: swiperState))
    }
}
