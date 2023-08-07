import Foundation
import SwiftUI

/// UIHostingController that support dynamical height
class UIBottomSheetHostingController<Content: View>: UIHostingController<Content>, CustomPresentableViewController {
    // MARK: - Properties

    /// transactionManager required by CustomPresentableViewController
    var transitionManager: UIViewControllerTransitioningDelegate?

    /// (Optional) Custom modifier for height in case of custom modification needed
    var heightModifier: ((CGFloat) -> CGFloat)?

    // MARK: - CustomPresentableViewController

    /// fitting size for presented view, required by CustomPresentableViewController
    func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        var expectedHeight = view.fittingHeight(targetWidth: targetWidth)
        expectedHeight = heightModifier?(expectedHeight) ?? expectedHeight
        // ignore safe area inset
        let window = UIApplication.shared.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        expectedHeight -= bottomPadding
        // return expected height
        return expectedHeight
    }
}
