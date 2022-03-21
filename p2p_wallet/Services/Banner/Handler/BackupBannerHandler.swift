//
// Created by Giang Long Tran on 18.02.2022.
//

import Foundation
import RxSwift
import SwiftyUserDefaults

class BackupBanner: Banners.Banner {
    static fileprivate let id = "backup-banner"

    init() {
        super.init(
            id: BackupBanner.id,
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
    var defaultsDisposable: DefaultsDisposable!

    init(backupStorage: ICloudStorageType) { self.backupStorage = backupStorage }

    func onRegister(with service: Banners.Service) {
        delegate = service

        // Subscribe backup on change
        backupStorage
            .onValueChange
            .emit(onNext: { [weak self] event in
                debugPrint("Backup Banner", event)
                if event.key == "didBackupUsingIcloud" && event.value != nil {
                    self?.delegate?.remove(bannerId: BackupBanner.id)
                }
            })
            .disposed(by: disposeBag)
        
        if Defaults.didBackupOffline {
            delegate?.remove(bannerId: BackupBanner.id)
        }
        
        defaultsDisposable = Defaults.observe(\.didBackupOffline) { [weak self] update in
            guard update.newValue == true else {return}
            self?.delegate?.remove(bannerId: BackupBanner.id)
        }

        // Check
        if backupStorage.didBackupUsingIcloud == false {
            delegate?.update(banner: BackupBanner())
        }
    }
    
    deinit {
        debugPrint("deuinit")
    }
}
