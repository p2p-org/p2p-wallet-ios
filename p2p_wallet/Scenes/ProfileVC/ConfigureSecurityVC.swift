//
//  ConfigureSecurityVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation
import LocalAuthentication

class ConfigureSecurityVC: ProfileVCBase {
    lazy var biometrySwitcher: UISwitch = {
        let switcher = UISwitch()
        switcher.tintColor = .textWhite
        switcher.onTintColor = .textBlack
        switcher.addTarget(self, action: #selector(switcherDidChange(_:)), for: .valueChanged)
        return switcher
    }()
    
    override func setUp() {
        title = L10n.security
        super.setUp()
        stackView.addArrangedSubviews([
            UIView.row([
                UIImageView(width: 44, height: 44, backgroundColor: .c4c4c4, cornerRadius: 22),
                UIView.col([
                    UILabel(text: LABiometryType.current.stringValue, textSize: 15, weight: .medium),
                    UILabel(text: L10n.willBeAsAPrimarySecureCheck, textSize: 12, textColor: .secondary, numberOfLines: 0)
                ]).with(spacing: 5),
                biometrySwitcher
            ])
                .with(spacing: 16, alignment: .center, distribution: .fill)
                .padding(.init(x: 0, y: 20)),
            UIView.row([
                UIImageView(width: 44, height: 44, backgroundColor: .c4c4c4, cornerRadius: 22),
                UIView.col([
                    UILabel(text: L10n.pinCode, textSize: 15, weight: .medium),
                    UILabel(text: L10n.defaultSecureCheck, textSize: 12, textColor: .secondary, numberOfLines: 0)
                ]).with(spacing: 5),
                UIImageView(width: 4.5, height: 9, image: .nextArrow, tintColor: .textBlack)
            ])
                .with(spacing: 16, alignment: .center, distribution: .fill)
                .padding(.init(x: 0, y: 20))
//            .onTap(self, action: )
        ])
        
        biometrySwitcher.isOn = Defaults.isBiometryEnabled
    }
    
    @objc func switcherDidChange(_ switcher: UISwitch) {
        Defaults.isBiometryEnabled.toggle()
    }
}
