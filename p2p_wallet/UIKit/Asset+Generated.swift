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
    static let a3a5baStatic = UIColor(named: "a3a5ba-static", in: bundle, compatibleWith: nil)!
    static let a3a5ba = UIColor(named: "a3a5ba", in: bundle, compatibleWith: nil)!
    static let a4a4a4 = UIColor(named: "a4a4a4", in: bundle, compatibleWith: nil)!
    static let alertOrange = UIColor(named: "alert-orange", in: bundle, compatibleWith: nil)!
    static let alert = UIColor(named: "alert", in: bundle, compatibleWith: nil)!
    static let attentionGreen = UIColor(named: "attention-green", in: bundle, compatibleWith: nil)!
    static let background2 = UIColor(named: "background-2", in: bundle, compatibleWith: nil)!
    static let background4 = UIColor(named: "background-4", in: bundle, compatibleWith: nil)!
    static let background5 = UIColor(named: "background-5", in: bundle, compatibleWith: nil)!
    static let background = UIColor(named: "background", in: bundle, compatibleWith: nil)!
    static let blackButtonBackground = UIColor(named: "black-button-background", in: bundle, compatibleWith: nil)!
    static let buttonSub = UIColor(named: "buttonSub", in: bundle, compatibleWith: nil)!
    static let c4c4c4 = UIColor(named: "c4c4c4", in: bundle, compatibleWith: nil)!
    static let coinGenericBackground = UIColor(named: "coin-generic-background", in: bundle, compatibleWith: nil)!
    static let contentBackground = UIColor(named: "content-background", in: bundle, compatibleWith: nil)!
    static let defaultBorder = UIColor(named: "default-border", in: bundle, compatibleWith: nil)!
    static let e5e5e5 = UIColor(named: "e5e5e5", in: bundle, compatibleWith: nil)!
    static let ededed = UIColor(named: "ededed", in: bundle, compatibleWith: nil)!
    static let eff3ff = UIColor(named: "eff3ff", in: bundle, compatibleWith: nil)!
    static let f3f3f3 = UIColor(named: "f3f3f3", in: bundle, compatibleWith: nil)!
    static let f4f4f4 = UIColor(named: "f4f4f4", in: bundle, compatibleWith: nil)!
    static let f5f5f5 = UIColor(named: "f5f5f5", in: bundle, compatibleWith: nil)!
    static let f6f6f8 = UIColor(named: "f6f6f8", in: bundle, compatibleWith: nil)!
    static let f6f6f8Static = UIColor(named: "f6f6f8Static", in: bundle, compatibleWith: nil)!
    static let fafafa = UIColor(named: "fafafa", in: bundle, compatibleWith: nil)!
    static let fbfbfd = UIColor(named: "fbfbfd", in: bundle, compatibleWith: nil)!
    static let grayMain = UIColor(named: "gray-main", in: bundle, compatibleWith: nil)!
    static let grayPanel = UIColor(named: "gray-panel", in: bundle, compatibleWith: nil)!
    static let greenConfirmed = UIColor(named: "green-confirmed", in: bundle, compatibleWith: nil)!
    static let h1b1b1b = UIColor(named: "h1b1b1b", in: bundle, compatibleWith: nil)!
    static let h202020 = UIColor(named: "h202020", in: bundle, compatibleWith: nil)!
    static let h230b34 = UIColor(named: "h230b34", in: bundle, compatibleWith: nil)!
    static let h282828 = UIColor(named: "h282828", in: bundle, compatibleWith: nil)!
    static let h2b2b2b = UIColor(named: "h2b2b2b", in: bundle, compatibleWith: nil)!
    static let h2e2e2e = UIColor(named: "h2e2e2e", in: bundle, compatibleWith: nil)!
    static let h2f2f2f = UIColor(named: "h2f2f2f", in: bundle, compatibleWith: nil)!
    static let h404040 = UIColor(named: "h404040", in: bundle, compatibleWith: nil)!
    static let h464646 = UIColor(named: "h464646", in: bundle, compatibleWith: nil)!
    static let h5887ff = UIColor(named: "h5887ff", in: bundle, compatibleWith: nil)!
    static let h6d6d6d = UIColor(named: "h6d6d6d", in: bundle, compatibleWith: nil)!
    static let h8b94a9 = UIColor(named: "h8b94a9", in: bundle, compatibleWith: nil)!
    static let h8d8d8d = UIColor(named: "h8d8d8d", in: bundle, compatibleWith: nil)!
    static let iconSecondary = UIColor(named: "icon-secondary", in: bundle, compatibleWith: nil)!
    static let indicator = UIColor(named: "indicator", in: bundle, compatibleWith: nil)!
    static let introBgStatic = UIColor(named: "intro-bg-static", in: bundle, compatibleWith: nil)!
    static let listBackground = UIColor(named: "list-background", in: bundle, compatibleWith: nil)!
    static let passcodeHighlightColor = UIColor(named: "passcode-highlight-color", in: bundle, compatibleWith: nil)!
    static let pinViewButtonBgColor = UIColor(named: "pinView-button-bg-color", in: bundle, compatibleWith: nil)!
    static let separator = UIColor(named: "separator", in: bundle, compatibleWith: nil)!
    static let tabbarSelected = UIColor(named: "tabbar-selected", in: bundle, compatibleWith: nil)!
    static let tabbarUnselected = UIColor(named: "tabbar-unselected", in: bundle, compatibleWith: nil)!
    static let tagBackground = UIColor(named: "tag-background", in: bundle, compatibleWith: nil)!
    static let tagBorder = UIColor(named: "tag-border", in: bundle, compatibleWith: nil)!
    static let textGreen = UIColor(named: "text-green", in: bundle, compatibleWith: nil)!
    static let textSecondary = UIColor(named: "text-secondary", in: bundle, compatibleWith: nil)!
    static let textBlack = UIColor(named: "textBlack", in: bundle, compatibleWith: nil)!
    static let textWhite = UIColor(named: "textWhite", in: bundle, compatibleWith: nil)!
}

// MARK: - Images -

extension UIImage {
    static let present = UIImage(named: "Present", in: bundle, compatibleWith: nil)!
    static let sol = UIImage(named: "SOL", in: bundle, compatibleWith: nil)!
    static let search = UIImage(named: "Search", in: bundle, compatibleWith: nil)!
    static let alert = UIImage(named: "alert", in: bundle, compatibleWith: nil)!
    static let backArrow = UIImage(named: "back-arrow", in: bundle, compatibleWith: nil)!
    static let backButtonDark = UIImage(named: "back-button-dark", in: bundle, compatibleWith: nil)!
    static let backButton = UIImage(named: "back-button", in: bundle, compatibleWith: nil)!
    static let backSquare = UIImage(named: "back-square", in: bundle, compatibleWith: nil)!
    static let backupShield = UIImage(named: "backup-shield", in: bundle, compatibleWith: nil)!
    static let buttonEdit = UIImage(named: "button-edit", in: bundle, compatibleWith: nil)!
    static let checkMark = UIImage(named: "check-mark", in: bundle, compatibleWith: nil)!
    static let closeFill = UIImage(named: "close-fill", in: bundle, compatibleWith: nil)!
    static let closeToken = UIImage(named: "close-token", in: bundle, compatibleWith: nil)!
    static let close = UIImage(named: "close", in: bundle, compatibleWith: nil)!
    static let connectionError = UIImage(named: "connection-error", in: bundle, compatibleWith: nil)!
    static let copyToClipboard = UIImage(named: "copy-to-clipboard", in: bundle, compatibleWith: nil)!
    static let delete = UIImage(named: "delete", in: bundle, compatibleWith: nil)!
    static let downArrowLight = UIImage(named: "down-arrow-light", in: bundle, compatibleWith: nil)!
    static let downArrow = UIImage(named: "down-arrow", in: bundle, compatibleWith: nil)!
    static let emptyPlaceholder = UIImage(named: "empty-placeholder", in: bundle, compatibleWith: nil)!
    static let faceId = UIImage(named: "faceId", in: bundle, compatibleWith: nil)!
    static let infoCircle = UIImage(named: "info-circle", in: bundle, compatibleWith: nil)!
    static let introLinesBg = UIImage(named: "intro-lines-bg", in: bundle, compatibleWith: nil)!
    static let link = UIImage(named: "link", in: bundle, compatibleWith: nil)!
    static let lock = UIImage(named: "lock", in: bundle, compatibleWith: nil)!
    static let nextArrow = UIImage(named: "next-arrow", in: bundle, compatibleWith: nil)!
    static let nothingFound = UIImage(named: "nothing-found", in: bundle, compatibleWith: nil)!
    static let orcaLogo = UIImage(named: "orca-logo", in: bundle, compatibleWith: nil)!
    static let orcaText = UIImage(named: "orca-text", in: bundle, compatibleWith: nil)!
    static let p2pValidatorLogo = UIImage(named: "p2p-validator-logo", in: bundle, compatibleWith: nil)!
    static let p2pWalletLogo = UIImage(named: "p2p-wallet-logo", in: bundle, compatibleWith: nil)!
    static let passcodeChanged = UIImage(named: "passcode-changed", in: bundle, compatibleWith: nil)!
    static let qrCodeRange = UIImage(named: "qr-code-range", in: bundle, compatibleWith: nil)!
    static let questionMarkCircle = UIImage(named: "question-mark-circle", in: bundle, compatibleWith: nil)!
    static let receiveQrCodeFrame = UIImage(named: "receive-qr-code-frame", in: bundle, compatibleWith: nil)!
    static let regenerateButton = UIImage(named: "regenerate-button", in: bundle, compatibleWith: nil)!
    static let reverseButton = UIImage(named: "reverse-button", in: bundle, compatibleWith: nil)!
    static let scanQr2 = UIImage(named: "scan-qr-2", in: bundle, compatibleWith: nil)!
    static let scanQr3 = UIImage(named: "scan-qr-3", in: bundle, compatibleWith: nil)!
    static let scanQr = UIImage(named: "scan-qr", in: bundle, compatibleWith: nil)!
    static let securityKey = UIImage(named: "security-key", in: bundle, compatibleWith: nil)!
    static let serumLogo = UIImage(named: "serum-logo", in: bundle, compatibleWith: nil)!
    static let settingsAppearance = UIImage(named: "settings-appearance", in: bundle, compatibleWith: nil)!
    static let settingsBackup = UIImage(named: "settings-backup", in: bundle, compatibleWith: nil)!
    static let settingsCurrency = UIImage(named: "settings-currency", in: bundle, compatibleWith: nil)!
    static let settingsFreeTransactions = UIImage(named: "settings-free-transactions", in: bundle, compatibleWith: nil)!
    static let settingsLanguage = UIImage(named: "settings-language", in: bundle, compatibleWith: nil)!
    static let settingsLogout = UIImage(named: "settings-logout", in: bundle, compatibleWith: nil)!
    static let settingsNetwork = UIImage(named: "settings-network", in: bundle, compatibleWith: nil)!
    static let settingsNode = UIImage(named: "settings-node", in: bundle, compatibleWith: nil)!
    static let settingsPincode = UIImage(named: "settings-pincode", in: bundle, compatibleWith: nil)!
    static let settingsSecurity = UIImage(named: "settings-security", in: bundle, compatibleWith: nil)!
    static let settings = UIImage(named: "settings", in: bundle, compatibleWith: nil)!
    static let share = UIImage(named: "share", in: bundle, compatibleWith: nil)!
    static let slippageEdit = UIImage(named: "slippage-edit", in: bundle, compatibleWith: nil)!
    static let slippageSettings = UIImage(named: "slippage-settings", in: bundle, compatibleWith: nil)!
    static let spinnerIcon = UIImage(named: "spinner-icon", in: bundle, compatibleWith: nil)!
    static let tabbarActivities = UIImage(named: "tabbar-activities", in: bundle, compatibleWith: nil)!
    static let tabbarFriends = UIImage(named: "tabbar-friends", in: bundle, compatibleWith: nil)!
    static let tabbarHome = UIImage(named: "tabbar-home", in: bundle, compatibleWith: nil)!
    static let textfieldClear = UIImage(named: "textfield-clear", in: bundle, compatibleWith: nil)!
    static let tokenExampleStack = UIImage(named: "token-example-stack", in: bundle, compatibleWith: nil)!
    static let touchId = UIImage(named: "touchId", in: bundle, compatibleWith: nil)!
    static let transactionCloseAccount = UIImage(named: "transaction-close-account", in: bundle, compatibleWith: nil)!
    static let transactionCreateAccount = UIImage(named: "transaction-create-account", in: bundle, compatibleWith: nil)!
    static let transactionEmpty = UIImage(named: "transaction-empty", in: bundle, compatibleWith: nil)!
    static let transactionErrorInvalidAccountInfo = UIImage(named: "transaction-error-invalid-account-info", in: bundle, compatibleWith: nil)!
    static let transactionErrorSlippageExceeded = UIImage(named: "transaction-error-slippage-exceeded", in: bundle, compatibleWith: nil)!
    static let transactionErrorSystem = UIImage(named: "transaction-error-system", in: bundle, compatibleWith: nil)!
    static let transactionErrorWrongWallet = UIImage(named: "transaction-error-wrong-wallet", in: bundle, compatibleWith: nil)!
    static let transactionError = UIImage(named: "transaction-error", in: bundle, compatibleWith: nil)!
    static let transactionIndicatorError = UIImage(named: "transaction-indicator-error", in: bundle, compatibleWith: nil)!
    static let transactionIndicatorPending = UIImage(named: "transaction-indicator-pending", in: bundle, compatibleWith: nil)!
    static let transactionInfoIcon = UIImage(named: "transaction-info-icon", in: bundle, compatibleWith: nil)!
    static let transactionProcessing = UIImage(named: "transaction-processing", in: bundle, compatibleWith: nil)!
    static let transactionReceive = UIImage(named: "transaction-receive", in: bundle, compatibleWith: nil)!
    static let transactionSend = UIImage(named: "transaction-send", in: bundle, compatibleWith: nil)!
    static let transactionSuccess = UIImage(named: "transaction-success", in: bundle, compatibleWith: nil)!
    static let transactionSwap = UIImage(named: "transaction-swap", in: bundle, compatibleWith: nil)!
    static let transactionUndefined = UIImage(named: "transaction-undefined", in: bundle, compatibleWith: nil)!
    static let turnOnNotification = UIImage(named: "turn-on-notification", in: bundle, compatibleWith: nil)!
    static let visibilityHide = UIImage(named: "visibility-hide", in: bundle, compatibleWith: nil)!
    static let visibilityShow = UIImage(named: "visibility-show", in: bundle, compatibleWith: nil)!
    static let walletAdd = UIImage(named: "wallet-add", in: bundle, compatibleWith: nil)!
    static let walletEdit = UIImage(named: "wallet-edit", in: bundle, compatibleWith: nil)!
    static let walletIcon = UIImage(named: "wallet-icon", in: bundle, compatibleWith: nil)!
    static let walletIntro = UIImage(named: "wallet-intro", in: bundle, compatibleWith: nil)!
    static let walletPlaceholder = UIImage(named: "wallet-placeholder", in: bundle, compatibleWith: nil)!
    static let walletReceive = UIImage(named: "wallet-receive", in: bundle, compatibleWith: nil)!
    static let walletSend = UIImage(named: "wallet-send", in: bundle, compatibleWith: nil)!
    static let walletShare = UIImage(named: "wallet-share", in: bundle, compatibleWith: nil)!
    static let walletSwap = UIImage(named: "wallet-swap", in: bundle, compatibleWith: nil)!
    static let warning = UIImage(named: "warning", in: bundle, compatibleWith: nil)!
    static let welcomeBack = UIImage(named: "welcome-back", in: bundle, compatibleWith: nil)!
    static let wrappedToken = UIImage(named: "wrapped-token", in: bundle, compatibleWith: nil)!
}

