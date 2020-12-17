// swiftlint:disable all
/// Attention: Changes made to this file will not have any effect and will be reverted 
/// when building the project. Please adjust the Stencil template `asset_extensions.stencil` instead.
/// See https://github.com/SwiftGen/SwiftGen#bundled-templates-vs-custom-ones for more information.

import UIKit

// MARK: - Private Helper -

private final class BundleToken {}
private let bundle = Bundle(for: BundleToken.self)

// MARK: - Colors -

extension UIColor {
    static let a4a4a4 = UIColor(named: "a4a4a4", in: bundle, compatibleWith: nil)!
    static let background = UIColor(named: "background", in: bundle, compatibleWith: nil)!
    static let buttonSub = UIColor(named: "buttonSub", in: bundle, compatibleWith: nil)!
    static let c4c4c4 = UIColor(named: "c4c4c4", in: bundle, compatibleWith: nil)!
    static let ededed = UIColor(named: "ededed", in: bundle, compatibleWith: nil)!
    static let f4f4f4 = UIColor(named: "f4f4f4", in: bundle, compatibleWith: nil)!
    static let f5f5f5 = UIColor(named: "f5f5f5", in: bundle, compatibleWith: nil)!
    static let fafafa = UIColor(named: "fafafa", in: bundle, compatibleWith: nil)!
    static let h202020 = UIColor(named: "h202020", in: bundle, compatibleWith: nil)!
    static let h282828 = UIColor(named: "h282828", in: bundle, compatibleWith: nil)!
    static let h5887ff = UIColor(named: "h5887ff", in: bundle, compatibleWith: nil)!
    static let lightGrayBackground = UIColor(named: "lightGrayBackground", in: bundle, compatibleWith: nil)!
    static let pinViewBgColor = UIColor(named: "pinView-bg-color", in: bundle, compatibleWith: nil)!
    static let pinViewButtonBgColor = UIColor(named: "pinView-button-bg-color", in: bundle, compatibleWith: nil)!
    static let textBlack = UIColor(named: "textBlack", in: bundle, compatibleWith: nil)!
    static let textWhite = UIColor(named: "textWhite", in: bundle, compatibleWith: nil)!
    static let vcBackground = UIColor(named: "vcBackground", in: bundle, compatibleWith: nil)!
}

// MARK: - Images -

extension UIImage {
    static let backArrow = UIImage(named: "back-arrow", in: bundle, compatibleWith: nil)!
    static let backButton = UIImage(named: "back-button", in: bundle, compatibleWith: nil)!
    static let backupShield = UIImage(named: "backup-shield", in: bundle, compatibleWith: nil)!
    static let checkMark = UIImage(named: "check-mark", in: bundle, compatibleWith: nil)!
    static let close = UIImage(named: "close", in: bundle, compatibleWith: nil)!
    static let copyToClipboard = UIImage(named: "copy-to-clipboard", in: bundle, compatibleWith: nil)!
    static let delete = UIImage(named: "delete", in: bundle, compatibleWith: nil)!
    static let downArrow = UIImage(named: "down-arrow", in: bundle, compatibleWith: nil)!
    static let emptyPlaceholder = UIImage(named: "empty-placeholder", in: bundle, compatibleWith: nil)!
    static let faceId = UIImage(named: "faceId", in: bundle, compatibleWith: nil)!
    static let introBankCard1 = UIImage(named: "intro-bank-card-1", in: bundle, compatibleWith: nil)!
    static let nextArrow = UIImage(named: "next-arrow", in: bundle, compatibleWith: nil)!
    static let p2pValidatorLogo = UIImage(named: "p2p-validator-logo", in: bundle, compatibleWith: nil)!
    static let qrCodeRange = UIImage(named: "qr-code-range", in: bundle, compatibleWith: nil)!
    static let regenerateButton = UIImage(named: "regenerate-button", in: bundle, compatibleWith: nil)!
    static let reverseButton = UIImage(named: "reverse-button", in: bundle, compatibleWith: nil)!
    static let scanQr = UIImage(named: "scan-qr", in: bundle, compatibleWith: nil)!
    static let tabbarProfile = UIImage(named: "tabbar-profile", in: bundle, compatibleWith: nil)!
    static let tabbarSearch = UIImage(named: "tabbar-search", in: bundle, compatibleWith: nil)!
    static let tabbarThunderbolt = UIImage(named: "tabbar-thunderbolt", in: bundle, compatibleWith: nil)!
    static let tabbarWallet = UIImage(named: "tabbar-wallet", in: bundle, compatibleWith: nil)!
    static let touchId = UIImage(named: "touchId", in: bundle, compatibleWith: nil)!
    static let transactionInfoIcon = UIImage(named: "transaction-info-icon", in: bundle, compatibleWith: nil)!
    static let walletIntro = UIImage(named: "wallet-intro", in: bundle, compatibleWith: nil)!
}

