import Foundation
import SolanaSwift
import UIKit

extension WrappingToken {
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
//        UIImage(named: "wrapped-by-" + rawValue)
        // swiftlint:enable swiftgen_assets
        UIImage.wrappedToken
    }
}
