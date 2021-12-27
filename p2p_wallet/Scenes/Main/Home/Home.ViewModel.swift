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
    var bannersDriver: Driver<[BannerViewContent]> { get }
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
        @Injected var bannersManager: BannersManagerType
        @Injected var bannersKindTransformer: BannerKindTransformerType
        @Injected var notificationsService: NotificationsServiceType
        
        // MARK: - Properties
        let walletsRepository: WalletsRepository
        let pricesService: PricesServiceType
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let nameDidReserveSubject = PublishRelay<Void>()
        
        // MARK: - Initializers
        init(walletsRepository: WalletsRepository, pricesService: PricesServiceType) {
            self.walletsRepository = walletsRepository
            self.pricesService = pricesService
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension Home.ViewModel: HomeViewModelType {
    var bannersDriver: Driver<[BannerViewContent]> {
        bannersManager.actualBannersSubject
            .map { [weak self] in
                guard let self = self else { return [] }

                return $0.map {
                    self.bannersKindTransformer.transformBannerKind(
                        $0,
                        closeHandler: self.closeBannerHandler(bannerKind: $0),
                        selectionHandler: self.bannerSelectionHandler(bannerKind: $0)
                    )
                }
            }
            .asDriver(onErrorJustReturn: [])
    }

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

    private func bannerSelectionHandler(bannerKind: BannerKind) -> () -> Void {
        { [weak self] in
            self?.selectBanner(bannerKind)
        }
    }

    private func closeBannerHandler(bannerKind: BannerKind) -> () -> Void {
        { [weak self] in
            self?.closeBanner(bannerKind)
        }
    }

    private func selectBanner(_ kind: BannerKind) {
        switch kind {
        case .reserveUsername:
            navigationSubject.accept(
                .reserveName(
                    owner: storage.account?.publicKey.base58EncodedString ?? ""
                )
            )
        }
    }

    private func closeBanner(_ kind: BannerKind) {
        switch kind {
        case .reserveUsername:
            let handler: (Home.ClosingBannerType) -> Void = { [weak self] closingType in
                switch closingType {
                case .forever:
                    self?.bannersManager.removeForever(bannerKind: kind)
                case .temporary:
                    self?.bannersManager.removeForSession(bannerKind: kind)
                }
            }
            navigationSubject.accept(.closeReserveNameAlert(handler))
        }
    }
}
