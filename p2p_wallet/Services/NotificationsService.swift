//
//  NotificationsService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2021.
//

import Foundation
import UIKit

protocol NotificationsServiceType {
    func showInAppNotification(_ notification: InAppNotification)
}

class NotificationsService: NotificationsServiceType {
    func showInAppNotification(_ notification: InAppNotification) {
        UIApplication.shared.showToast(message: createTextFromNotification(notification))
    }

    private func createTextFromNotification(_ notification: InAppNotification) -> String {
        var array = [String]()
        if let emoji = notification.emoji {
            array.append(emoji)
        }
        array.append(notification.message)
        return array.joined(separator: " ")
    }
}

private extension UIApplication {
    func showToast(
        message: String?,
        backgroundColor: UIColor = .h2c2c2e,
        alpha: CGFloat = 0.8,
        shadowColor: UIColor = .h6d6d6d.onDarkMode(.black),
        completion: (() -> Void)? = nil
    ) {
        guard let message = message else { return }

        let toast = BERoundedCornerShadowView(
            shadowColor: shadowColor,
            radius: 16,
            offset: .init(width: 0, height: 8),
            opacity: 1,
            cornerRadius: 12,
            contentInset: .init(x: 20, y: 10)
        )
        toast.backgroundColor = backgroundColor
        toast.mainView.alpha = alpha

        let label = UILabel(text: message, textSize: 15, textColor: .white, numberOfLines: 0, textAlignment: .center)
        label.tag = 1

        toast.stackView.addArrangedSubview(label)
        toast.autoSetDimension(.width, toSize: 335, relation: .lessThanOrEqual)

        kWindow?.addSubview(toast)
        toast.autoAlignAxis(toSuperviewAxis: .vertical)
        toast.autoPinEdge(toSuperviewSafeArea: .top, withInset: -100)

        kWindow?.bringSubviewToFront(toast)
        kWindow?.layoutIfNeeded()
        toast.constraintToSuperviewWithAttribute(.top)?.constant = 25

        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.kWindow?.layoutIfNeeded()
        } completion: { _ in
            completion?()

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self, weak toast] in
                toast?.constraintToSuperviewWithAttribute(.top)?.constant = -100

                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.kWindow?.layoutIfNeeded()
                } completion: { [weak toast] _ in
                    toast?.removeFromSuperview()
                }
            }
        }
    }
}
