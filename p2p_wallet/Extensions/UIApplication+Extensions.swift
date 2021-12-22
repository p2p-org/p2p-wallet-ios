//
//  UIApplication+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation

extension UIApplication {
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
    
    
    
    func showToast(
        message: String?,
        backgroundColor: UIColor = .black,
        alpha: CGFloat = 0.8,
        shadowColor: UIColor = .h6d6d6d.onDarkMode(.black),
        completion: (() -> Void)? = nil
    ) {
        guard let message = message else {return}
        
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
        
        let label = UILabel(text: message, textSize: 15, weight: .semibold, textColor: .white, numberOfLines: 0, textAlignment: .center)
        label.tag = 1
        
        toast.stackView.addArrangedSubview(label)
        toast.autoSetDimension(.width, toSize: 335, relation: .lessThanOrEqual)
        
        kWindow?.addSubview(toast)
        toast.autoAlignAxis(toSuperviewAxis: .vertical)
        toast.autoPinEdge(toSuperviewSafeArea: .top, withInset: -100)
        
        kWindow?.bringSubviewToFront(toast)
        kWindow?.layoutIfNeeded()
        toast.constraintToSuperviewWithAttribute(.top)?.constant = 25
        
        UIView.animate(withDuration: 0.3) {[weak self] in
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
