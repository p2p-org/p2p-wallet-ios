//
//  UIApplication+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import MBProgressHUD

extension UIApplication {
    private static let toastTag = 70457
    
    private var kWindow: UIWindow? {
        // keyWindow is deprecated
        UIApplication.shared.windows.first { $0.isKeyWindow }
    }
    
    func showIndetermineHud() {
        kWindow?.showIndetermineHud()
    }
    
    func hideHud() {
        kWindow?.hideHud()
    }
    
    func showLoadingIndicatorView(isBlocking: Bool = true) {
        kWindow?.showLoadingIndicatorView(isBlocking: isBlocking)
    }
    
    func hideLoadingIndicatorView() {
        kWindow?.hideLoadingIndicatorView()
    }
    
    func openAppSettings() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier, let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) {
            if canOpenURL(appSettings) {
                open(appSettings)
            }
        }
    }
    
    func copyToClipboard(_ text: String?, alert: Bool = true, alertMessage: String? = nil) {
        UIPasteboard.general.string = text
        if alert {
            showToast(message: alertMessage ?? L10n.copiedToClipboard)
        }
    }
    
    func showToast(message: String?) {
        guard let message = message else {return}
        var toast: UIView?
        if let currentToast = kWindow?.viewWithTag(UIApplication.toastTag) {
            toast = currentToast
            toast?.constraintToSuperviewWithAttribute(.top)?.constant = -100
            toast?.setNeedsLayout()
        } else {
            let newToast = BERoundedCornerShadowView(shadowColor: .white.withAlphaComponent(0.15), radius: 16, offset: .zero, opacity: 1, cornerRadius: 12, contentInset: .init(x: 20, y: 10))
            newToast.mainView.backgroundColor = .h202020.onDarkMode(.h202020)
            let label = UILabel(text: L10n.addressCopiedToClipboard, textSize: 15, weight: .semibold, textColor: .white, numberOfLines: 0, textAlignment: .center)
            label.tag = 1
            newToast.stackView.addArrangedSubview(
                label
            )
            newToast.autoSetDimension(.width, toSize: 335)
            newToast.tag = UIApplication.toastTag
            
            kWindow?.addSubview(newToast)
            newToast.autoAlignAxis(toSuperviewAxis: .vertical)
            newToast.autoPinEdge(toSuperviewSafeArea: .top, withInset: -100)
            
            toast = newToast
        }
        
        (toast?.viewWithTag(1) as? UILabel)?.text = message
        
        kWindow?.bringSubviewToFront(toast!)
        kWindow?.layoutIfNeeded()
        toast?.constraintToSuperviewWithAttribute(.top)?.constant = 25
        
        UIView.animate(withDuration: 0.3) {[weak self] in
            self?.kWindow?.layoutIfNeeded()
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self, weak toast] in
                toast?.constraintToSuperviewWithAttribute(.top)?.constant = -100

                UIView.animate(withDuration: 0.3) {
                    self?.kWindow?.layoutIfNeeded()
                }
            }
        }
        
    }
}
