//
//  Home.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import Foundation
import RxSwift
import RxCocoa
import Resolver

protocol HomeViewModelType: ReserveNameHandler {
    var navigationDriver: Driver<Home.NavigatableScene?> {get}
    var currentPricesDriver: Driver<Loadable<[String: CurrentPrice]>> {get}
    
    var nameDidReserveSignal: Signal<Void> {get}
    var walletsRepository: WalletsRepository {get}
    
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
    
    func navigateToScanQrCodeWithSwiper(progress: CGFloat, swiperState: UIGestureRecognizer.State) {
        navigationSubject.accept(.scanQrWithSwiper(progress: progress, state: swiperState))
    }
    
    func handleName(_ name: String?) {
        if let name = name {
            storage.save(name: name)
            Defaults.forceCloseNameServiceBanner = true
            notificationsService.showInAppNotification(
                .done(
                    L10n.usernameIsSuccessfullyReserved(name.withNameServiceDomain())
                )
            )
        }
        nameDidReserveSubject.accept(())
    }
}
