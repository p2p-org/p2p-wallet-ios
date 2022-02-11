//
//  PhotoLibraryAlertPresenter.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.02.2022.
//

import UIKit

final class PhotoLibraryAlertPresenter {
    func present(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: L10n.allowAccessToSaveYourPhotos,
            message: L10n.thisIsRequiredForTheAppToSaveGeneratedQRCodesOrBackUpOfYourSeedPhrasesToYourPhotoLibrary,
            preferredStyle: .alert
        )

        let notNowAction = UIAlertAction(
            title: L10n.cancel,
            style: .cancel,
            handler: nil
        )

        alert.addAction(notNowAction)

        let openSettingsAction = UIAlertAction(
            title: L10n.openSettings,
            style: .default,
            handler: goToAppPrivacySettings()
        )

        alert.addAction(openSettingsAction)

        viewController.present(alert, animated: true)
    }

    private func goToAppPrivacySettings() -> (UIAlertAction) -> Void {
        { _ in
            guard
                let url = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(url)
            else {
                return assertionFailure("Not able to open App privacy settings")
            }

            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
