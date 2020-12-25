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
    static let a3a5ba = UIColor(named: "a3a5ba", in: bundle, compatibleWith: nil)!
    static let a4a4a4 = UIColor(named: "a4a4a4", in: bundle, compatibleWith: nil)!
    static let attentionGreen = UIColor(named: "attention-green", in: bundle, compatibleWith: nil)!
    static let background2 = UIColor(named: "background-2", in: bundle, compatibleWith: nil)!
    static let background3 = UIColor(named: "background-3", in: bundle, compatibleWith: nil)!
    static let background4 = UIColor(named: "background-4", in: bundle, compatibleWith: nil)!
    static let background = UIColor(named: "background", in: bundle, compatibleWith: nil)!
    static let barChart1 = UIColor(named: "bar-chart-1", in: bundle, compatibleWith: nil)!
    static let barChart2 = UIColor(named: "bar-chart-2", in: bundle, compatibleWith: nil)!
    static let barChart3 = UIColor(named: "bar-chart-3", in: bundle, compatibleWith: nil)!
    static let barChart4 = UIColor(named: "bar-chart-4", in: bundle, compatibleWith: nil)!
    static let buttonSub = UIColor(named: "buttonSub", in: bundle, compatibleWith: nil)!
    static let c4c4c4 = UIColor(named: "c4c4c4", in: bundle, compatibleWith: nil)!
    static let ededed = UIColor(named: "ededed", in: bundle, compatibleWith: nil)!
    static let eff3ff = UIColor(named: "eff3ff", in: bundle, compatibleWith: nil)!
    static let f4f4f4 = UIColor(named: "f4f4f4", in: bundle, compatibleWith: nil)!
    static let f5f5f5 = UIColor(named: "f5f5f5", in: bundle, compatibleWith: nil)!
    static let f6f6f8 = UIColor(named: "f6f6f8", in: bundle, compatibleWith: nil)!
    static let fafafa = UIColor(named: "fafafa", in: bundle, compatibleWith: nil)!
    static let h1b1b1b = UIColor(named: "h1b1b1b", in: bundle, compatibleWith: nil)!
    static let h202020 = UIColor(named: "h202020", in: bundle, compatibleWith: nil)!
    static let h282828 = UIColor(named: "h282828", in: bundle, compatibleWith: nil)!
    static let h5887ff = UIColor(named: "h5887ff", in: bundle, compatibleWith: nil)!
    static let lightGrayBackground = UIColor(named: "lightGrayBackground", in: bundle, compatibleWith: nil)!
    static let pinViewBgColor = UIColor(named: "pinView-bg-color", in: bundle, compatibleWith: nil)!
    static let pinViewButtonBgColor = UIColor(named: "pinView-button-bg-color", in: bundle, compatibleWith: nil)!
    static let separator = UIColor(named: "separator", in: bundle, compatibleWith: nil)!
    static let tabbarSelected = UIColor(named: "tabbar-selected", in: bundle, compatibleWith: nil)!
    static let tabbarUnselected = UIColor(named: "tabbar-unselected", in: bundle, compatibleWith: nil)!
    static let textBlack = UIColor(named: "textBlack", in: bundle, compatibleWith: nil)!
    static let textWhite = UIColor(named: "textWhite", in: bundle, compatibleWith: nil)!
    static let vcBackground = UIColor(named: "vcBackground", in: bundle, compatibleWith: nil)!
}

// MARK: - Images -

extension UIImage {
    static let backArrow = UIImage(named: "back-arrow", in: bundle, compatibleWith: nil)!
    static let backButton = UIImage(named: "back-button", in: bundle, compatibleWith: nil)!
    static let backupShield = UIImage(named: "backup-shield", in: bundle, compatibleWith: nil)!
    static let buttonEdit = UIImage(named: "button-edit", in: bundle, compatibleWith: nil)!
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
    static let scanQr2 = UIImage(named: "scan-qr-2", in: bundle, compatibleWith: nil)!
    static let scanQr = UIImage(named: "scan-qr", in: bundle, compatibleWith: nil)!
    static let search = UIImage(named: "search", in: bundle, compatibleWith: nil)!
    static let tabbarActivities = UIImage(named: "tabbar-activities", in: bundle, compatibleWith: nil)!
    static let tabbarFriends = UIImage(named: "tabbar-friends", in: bundle, compatibleWith: nil)!
    static let tabbarHome = UIImage(named: "tabbar-home", in: bundle, compatibleWith: nil)!
    static let touchId = UIImage(named: "touchId", in: bundle, compatibleWith: nil)!
    static let transactionInfoIcon = UIImage(named: "transaction-info-icon", in: bundle, compatibleWith: nil)!
    static let walletAdd = UIImage(named: "wallet-add", in: bundle, compatibleWith: nil)!
    static let walletIntro = UIImage(named: "wallet-intro", in: bundle, compatibleWith: nil)!
    static let walletReceive = UIImage(named: "wallet-receive", in: bundle, compatibleWith: nil)!
    static let walletSend = UIImage(named: "wallet-send", in: bundle, compatibleWith: nil)!
    static let walletShare = UIImage(named: "wallet-share", in: bundle, compatibleWith: nil)!
    static let walletSwap = UIImage(named: "wallet-swap", in: bundle, compatibleWith: nil)!
}

