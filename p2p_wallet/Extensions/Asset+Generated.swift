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
    static let lightGrayBackground = UIColor(named: "lightGrayBackground", in: bundle, compatibleWith: nil)!
    static let textBlack = UIColor(named: "textBlack", in: bundle, compatibleWith: nil)!
    static let textWhite = UIColor(named: "textWhite", in: bundle, compatibleWith: nil)!
    static let vcBackground = UIColor(named: "vcBackground", in: bundle, compatibleWith: nil)!
}

// MARK: - Images -

extension UIImage {
    static let backButton = UIImage(named: "back-button", in: bundle, compatibleWith: nil)!
    static let close = UIImage(named: "close", in: bundle, compatibleWith: nil)!
    static let faceId = UIImage(named: "faceId", in: bundle, compatibleWith: nil)!
    static let graphDemo = UIImage(named: "graph-demo", in: bundle, compatibleWith: nil)!
    static let graphDetailDemo = UIImage(named: "graph-detail-demo", in: bundle, compatibleWith: nil)!
    static let scanQr = UIImage(named: "scan-qr", in: bundle, compatibleWith: nil)!
    static let tabbarProfile = UIImage(named: "tabbar-profile", in: bundle, compatibleWith: nil)!
    static let tabbarSearch = UIImage(named: "tabbar-search", in: bundle, compatibleWith: nil)!
    static let tabbarThunderbolt = UIImage(named: "tabbar-thunderbolt", in: bundle, compatibleWith: nil)!
    static let tabbarWallet = UIImage(named: "tabbar-wallet", in: bundle, compatibleWith: nil)!
    static let touchId = UIImage(named: "touchId", in: bundle, compatibleWith: nil)!
    static let walletIntro = UIImage(named: "wallet-intro", in: bundle, compatibleWith: nil)!
}

