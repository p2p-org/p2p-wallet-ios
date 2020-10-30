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
}

// MARK: - Images -

extension UIImage {
    static let faceId = UIImage(named: "faceId", in: bundle, compatibleWith: nil)!
    static let walletIntro = UIImage(named: "wallet-intro", in: bundle, compatibleWith: nil)!
}

