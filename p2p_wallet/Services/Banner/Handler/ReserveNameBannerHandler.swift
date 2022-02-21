//
// Created by Giang Long Tran on 18.02.2022.
//

import Foundation
import RxSwift

class ReserveNameBanner: Banners.Banner {
    static fileprivate let id = "reserve-banner"

    init() {
        super.init(
            id: ReserveNameBanner.id,
            priority: .veryHigh,
            onTap: Banners.OpenScreenAction(screen: "settings/reserve")
        )
    }

    override func getInfo() -> [InfoKey: Any] {
        [
            .title: L10n.getYourYourOwnShortCryptoAddress,
            .action: L10n.reserveYourUsername,
            .background: UIColor(red: 0.847, green: 0.953, blue: 0.886, alpha: 1),
            .icon: UIImage.bannerReserveName
        ]

    }
}

class ReserveNameBannerHandler: Banners.Handler {

    weak var delegate: Banners.Service?
    let nameStorage: NameStorageType
    let disposeBag = DisposeBag()

    init(nameStorage: NameStorageType) { self.nameStorage = nameStorage }

    func onRegister(with service: Banners.Service) {
        delegate = service

        // Subscribe to name storage
        nameStorage
            .onValueChange
            .emit(onNext: { [weak self] event in
                if event.key == "getName" && event.value != nil {
                    self?.delegate?.remove(bannerId: ReserveNameBanner.id)
                }
            })
            .disposed(by: disposeBag)

        // Check if name wasn't reserved
        if nameStorage.getName() == nil {
            delegate?.update(banner: ReserveNameBanner())
        }
    }
}
