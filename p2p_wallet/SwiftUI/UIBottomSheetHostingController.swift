//
//  UIBottomSheetHostingController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/01/2023.
//

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

extension UIBottomSheetHostingController {
    /// Convenience init for overriding default avoiding-keyboard behavior in UIHostingController
    /// WARNING: Don't know why convenience init(rootView:ignoresKeyboard:) not recognizable for UIBottomSheetHostingController in xcode 15, so I need to put this additional method.
    convenience public init(rootView: Content, shouldIgnoresKeyboard: Bool) {
        self.init(rootView: rootView)
        
        if shouldIgnoresKeyboard {
            disableLayoutWithKeyboard()
        }
    }
}
