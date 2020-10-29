// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Accept
  internal static let accept = L10n.tr("Localizable", "Accept")
  /// Backup
  internal static let backup = L10n.tr("Localizable", "Backup")
  /// By tapping accept, you agree to P2PWallet’s Terms of Use and Privacy Policy
  internal static let byTappingAcceptYouAgreeToP2PWalletSTermsOfUseAndPrivacyPolicy = L10n.tr("Localizable", "By tapping accept, you agree to P2PWallet’s Terms of Use and Privacy Policy")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "Cancel")
  /// Congratulations!
  internal static let congratulations = L10n.tr("Localizable", "Congratulations!")
  /// create new wallet
  internal static let createNewWallet = L10n.tr("Localizable", "create new wallet")
  /// creating an account
  internal static let creatingAnAccount = L10n.tr("Localizable", "creating an account")
  /// error
  internal static let error = L10n.tr("Localizable", "error")
  /// i've already had a wallet
  internal static let iVeAlreadyHadAWallet = L10n.tr("Localizable", "i've already had a wallet")
  /// next
  internal static let next = L10n.tr("Localizable", "next")
  /// OK
  internal static let ok = L10n.tr("Localizable", "OK")
  /// please try again later!
  internal static let pleaseTryAgainLater = L10n.tr("Localizable", "please try again later!")
  /// Terms and conditions
  internal static let termsAndConditions = L10n.tr("Localizable", "Terms and conditions")
  /// Wowlet for people, not for tokens
  internal static let wowletForPeopleNotForTokens = L10n.tr("Localizable", "Wowlet for people, not for tokens")
  /// Your wallet has been successfully created!
  internal static let yourWalletHasBeenSuccessfullyCreated = L10n.tr("Localizable", "Your wallet has been successfully created!")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
