//
// Created by Giang Long Tran on 18.02.2022.
//

import Foundation
import RxSwift

class BackupNameBanner: Banners.Banner {
    static fileprivate let id = "backup-banner"

    init() {
        super.init(
            id: BackupNameBanner.id,
            priority: .hight,
            onTapAction: Banners.Actions.OpenScreen(screen: "backup")
        )
    }

    override func getInfo() -> [InfoKey: Any] {
        [
            .title: L10n.yourWalletIsAtRiskIfYouDoNotBackItUp,
            .action: L10n.backUpYourWallet,
            .background: UIColor(red: 0.953, green: 0.929, blue: 0.847, alpha: 1),
            .icon: UIImage.bannerBackup
        ]
    }
}

class BackupBannerHandler: Banners.Handler {

    weak var delegate: Banners.Service?
    let backupStorage: ICloudStorageType
    let disposeBag = DisposeBag()

    init(backupStorage: ICloudStorageType) { self.backupStorage = backupStorage }

    func onRegister(with service: Banners.Service) {
        delegate = service

        // Subscribe backup on change
        backupStorage
            .onValueChange
            .emit(onNext: { [weak self] event in
                debugPrint("Backup Banner", event)
                if event.key == "didBackupUsingIcloud" && event.value != nil {
                    self?.delegate?.remove(bannerId: BackupNameBanner.id)
                }
            })
            .disposed(by: disposeBag)

        // Check
        if backupStorage.didBackupUsingIcloud == false {
            delegate?.update(banner: BackupNameBanner())
        }
    }
    
    deinit {
        debugPrint("deuinit")
    }
}
