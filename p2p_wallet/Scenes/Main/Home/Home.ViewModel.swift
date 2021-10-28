//
//  Home.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol HomeViewModelType: ReserveNameHandler {
    var navigationDriver: Driver<Home.NavigatableScene?> {get}
    var nameDidReserveSignal: Signal<Void> {get}
    var walletsRepository: WalletsRepository {get}
    
    func navigate(to scene: Home.NavigatableScene?)
    func navigateToScanQrCodeWithSwiper(progress: CGFloat, swiperState: UIGestureRecognizer.State)
}

extension Home {
    class ViewModel {
        // MARK: - Dependencies
        @Injected var keychainStorage: KeychainAccountStorage
        
        // MARK: - Properties
        let walletsRepository: WalletsRepository
        
        // MARK: - Subjects
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let nameDidReserveSubject = PublishRelay<Void>()
        
        // MARK: - Initializers
        init(walletsRepository: WalletsRepository) {
            self.walletsRepository = walletsRepository
        }
    }
}

extension Home.ViewModel: HomeViewModelType {
    var navigationDriver: Driver<Home.NavigatableScene?> {
        navigationSubject.asDriver()
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
            keychainStorage.save(name: name)
            Defaults.forceCloseNameServiceBanner = true
            UIApplication.shared.showToast(message: "✅ \(L10n.usernameIsSuccessfullyReserved(name.withNameServiceDomain()))")
        }
        nameDidReserveSubject.accept(())
    }
}
